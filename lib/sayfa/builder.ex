defmodule Sayfa.Builder do
  @moduledoc """
  Orchestrates the full site build pipeline.

  The builder runs through these stages:

  1. **Resolve config** — merge defaults, app env, and runtime options
  2. **Discover** — find all `.md` files in the content directory
  3. **Parse** — parse front matter and render Markdown for each file
  4. **Classify** — determine content type from directory structure, enrich with type metadata
  5. **Filter** — exclude drafts (unless `drafts: true`)
  6. **Render** — apply three-layer template pipeline for individual pages
  7. **Archives** — generate tag and category archive pages
  8. **Indexes** — generate paginated content type index pages
  9. **Write** — output HTML files to the output directory

  ## Examples

      # Build with defaults
      {:ok, result} = Sayfa.Builder.build()

      # Build with custom paths
      {:ok, result} = Sayfa.Builder.build(content_dir: "my_content", output_dir: "dist")

      # Clean output directory
      :ok = Sayfa.Builder.clean(output_dir: "dist")

  """

  alias Sayfa.Config
  alias Sayfa.Content
  alias Sayfa.ContentType
  alias Sayfa.Pagination
  alias Sayfa.Template

  defmodule Result do
    @moduledoc """
    Result of a successful build.
    """
    defstruct files_written: 0, content_count: 0, elapsed_ms: 0

    @type t :: %__MODULE__{
            files_written: non_neg_integer(),
            content_count: non_neg_integer(),
            elapsed_ms: non_neg_integer()
          }
  end

  @doc """
  Builds the site from content files to HTML output.

  ## Options

  All options from `Sayfa.Config.resolve/1` are accepted, plus:

  - `:content_dir` — source content directory (default: `"content"`)
  - `:output_dir` — output directory (default: `"output"`)
  - `:drafts` — include draft content (default: `false`)

  ## Examples

      {:ok, %Sayfa.Builder.Result{files_written: 2}} = Sayfa.Builder.build()

  """
  @spec build(keyword()) :: {:ok, Result.t()} | {:error, term()}
  def build(opts \\ []) do
    start_time = System.monotonic_time(:millisecond)
    config = Config.resolve(opts)

    with :ok <- verify_content_dir(config.content_dir),
         {:ok, files} <- discover_files(config.content_dir),
         {:ok, contents} <- parse_files(files, config.content_dir),
         contents <- filter_drafts(contents, config.drafts),
         {:ok, individual_count} <- render_and_write(contents, config),
         {:ok, archive_count} <- build_archives(contents, config),
         {:ok, index_count} <- build_type_indexes(contents, config) do
      elapsed = System.monotonic_time(:millisecond) - start_time

      {:ok,
       %Result{
         files_written: individual_count + archive_count + index_count,
         content_count: length(contents),
         elapsed_ms: elapsed
       }}
    end
  end

  @doc """
  Removes the output directory.

  ## Examples

      :ok = Sayfa.Builder.clean(output_dir: "output")

  """
  @spec clean(keyword()) :: :ok
  def clean(opts \\ []) do
    config = Config.resolve(opts)
    File.rm_rf!(config.output_dir)
    :ok
  end

  # --- Private Functions ---

  defp verify_content_dir(content_dir) do
    if File.dir?(content_dir) do
      :ok
    else
      {:error, {:content_dir_not_found, content_dir}}
    end
  end

  defp discover_files(content_dir) do
    files = Path.wildcard(Path.join(content_dir, "**/*.md"))
    {:ok, files}
  end

  defp parse_files(files, content_dir) do
    results =
      Enum.reduce_while(files, [], fn file, acc ->
        case Content.parse_file(file) do
          {:ok, content} ->
            content = classify_content(content, file, content_dir)
            {:cont, [content | acc]}

          {:error, reason} ->
            {:halt, {:error, {:parse_error, file, reason}}}
        end
      end)

    case results do
      {:error, _} = error -> error
      contents -> {:ok, Enum.reverse(contents)}
    end
  end

  defp classify_content(content, file_path, content_dir) do
    relative = Path.relative_to(file_path, content_dir)
    parts = Path.split(relative)

    directory =
      case parts do
        [dir | _rest] when length(parts) > 1 -> dir
        _ -> "pages"
      end

    meta = Map.put(content.meta, "content_type", directory)

    meta =
      case ContentType.find_by_directory(directory) do
        nil ->
          meta

        type_mod ->
          meta
          |> Map.put("default_layout", type_mod.default_layout())
          |> Map.put("url_prefix", type_mod.url_prefix())
      end

    %{content | meta: meta}
  end

  defp filter_drafts(contents, true), do: contents

  defp filter_drafts(contents, _) do
    Enum.reject(contents, & &1.draft)
  end

  defp render_and_write(contents, config) do
    results =
      Enum.reduce_while(contents, 0, fn content, count ->
        case render_and_write_one(content, config) do
          :ok -> {:cont, count + 1}
          {:error, _} = error -> {:halt, error}
        end
      end)

    case results do
      {:error, _} = error -> error
      count -> {:ok, count}
    end
  end

  defp render_and_write_one(content, config) do
    case Template.render_content(content, config: config) do
      {:ok, html} ->
        output_path = output_path_for(content, config.output_dir)
        dir = Path.dirname(output_path)
        File.mkdir_p!(dir)
        File.write!(output_path, html)
        :ok

      {:error, _} = error ->
        error
    end
  end

  defp output_path_for(content, output_dir) do
    url_prefix = content.meta["url_prefix"]

    case url_prefix do
      nil ->
        # Fallback for unrecognized content types
        content_type = content.meta["content_type"]

        case content_type do
          "pages" -> Path.join([output_dir, content.slug, "index.html"])
          type -> Path.join([output_dir, type, content.slug, "index.html"])
        end

      "" ->
        Path.join([output_dir, content.slug, "index.html"])

      prefix ->
        Path.join([output_dir, prefix, content.slug, "index.html"])
    end
  end

  # --- Archives (tags & categories) ---

  defp build_archives(contents, config) do
    with {:ok, tag_count} <- build_tag_archives(contents, config),
         {:ok, cat_count} <- build_category_archives(contents, config) do
      {:ok, tag_count + cat_count}
    end
  end

  defp build_tag_archives(contents, config) do
    tag_groups = Content.group_by_tag(contents)

    results =
      Enum.reduce_while(tag_groups, 0, fn {tag, items}, count ->
        sorted = Content.sort_by_date(items)
        slug = Slug.slugify(tag)

        case render_and_write_list(sorted, "Tagged: #{tag}", "/tags/#{slug}", config) do
          :ok -> {:cont, count + 1}
          {:error, _} = error -> {:halt, error}
        end
      end)

    case results do
      {:error, _} = error -> error
      count -> {:ok, count}
    end
  end

  defp build_category_archives(contents, config) do
    cat_groups = Content.group_by_category(contents)

    results =
      Enum.reduce_while(cat_groups, 0, fn {category, items}, count ->
        sorted = Content.sort_by_date(items)
        slug = Slug.slugify(category)

        case render_and_write_list(sorted, "Category: #{category}", "/categories/#{slug}", config) do
          :ok -> {:cont, count + 1}
          {:error, _} = error -> {:halt, error}
        end
      end)

    case results do
      {:error, _} = error -> error
      count -> {:ok, count}
    end
  end

  # --- Content Type Indexes ---

  defp build_type_indexes(contents, config) do
    page_size = Map.get(config, :posts_per_page, 10)

    # Build an index for each content type that has content
    type_groups =
      contents
      |> Enum.group_by(fn c -> c.meta["content_type"] end)
      |> Enum.reject(fn {type, _} -> type == "pages" end)

    results =
      Enum.reduce_while(type_groups, 0, fn {type, items}, total_count ->
        sorted = Content.sort_by_date(items)

        url_prefix =
          case ContentType.find_by_directory(type) do
            nil -> type
            mod -> mod.url_prefix()
          end

        base_path = "/#{url_prefix}"
        pages = Pagination.paginate(sorted, page_size: page_size, base_path: base_path)

        case write_paginated_index(pages, url_prefix, config) do
          {:ok, page_count} -> {:cont, total_count + page_count}
          {:error, _} = error -> {:halt, error}
        end
      end)

    case results do
      {:error, _} = error -> error
      count -> {:ok, count}
    end
  end

  defp write_paginated_index(pages, url_prefix, config) do
    results =
      Enum.reduce_while(pages, 0, fn page, count ->
        page_title = String.capitalize(url_prefix)

        output_path =
          case page.page_number do
            1 -> Path.join([config.output_dir, url_prefix, "index.html"])
            n -> Path.join([config.output_dir, url_prefix, "page", "#{n}", "index.html"])
          end

        case Template.render_list_page(
               config: config,
               contents: page.items,
               page_title: page_title,
               pagination: page
             ) do
          {:ok, html} ->
            dir = Path.dirname(output_path)
            File.mkdir_p!(dir)
            File.write!(output_path, html)
            {:cont, count + 1}

          {:error, _} = error ->
            {:halt, error}
        end
      end)

    case results do
      {:error, _} = error -> error
      count -> {:ok, count}
    end
  end

  # --- Shared List Rendering ---

  defp render_and_write_list(contents, page_title, url_path, config) do
    output_path =
      Path.join([config.output_dir, String.trim_leading(url_path, "/"), "index.html"])

    case Template.render_list_page(
           config: config,
           contents: contents,
           page_title: page_title,
           pagination: nil
         ) do
      {:ok, html} ->
        dir = Path.dirname(output_path)
        File.mkdir_p!(dir)
        File.write!(output_path, html)
        :ok

      {:error, _} = error ->
        error
    end
  end
end
