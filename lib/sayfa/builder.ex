defmodule Sayfa.Builder do
  @moduledoc """
  Orchestrates the full site build pipeline.

  The builder runs through these stages:

  1. **Resolve config** — merge defaults, app env, and runtime options
  2. **Discover** — find all `.md` files in the content directory
  3. **Parse** — parse front matter and render Markdown for each file
  4. **Classify** — determine content type from directory structure, enrich with type metadata
  5. **Filter** — exclude drafts (unless `drafts: true`)
  6. **Enrich** — add reading time and table of contents to content metadata
  7. **Render** — apply three-layer template pipeline for individual pages
  8. **Archives** — generate tag and category archive pages
  9. **Indexes** — generate paginated content type index pages
  10. **Feeds** — generate Atom feeds (main + per-type)
  11. **Sitemap** — generate XML sitemap
  12. **Pagefind** — run search indexing (optional, skipped if binary not found)

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
  alias Sayfa.Feed
  alias Sayfa.I18n
  alias Sayfa.Pagination
  alias Sayfa.ReadingTime
  alias Sayfa.Sitemap
  alias Sayfa.TOC
  alias Sayfa.Template

  require Logger

  defmodule Result do
    @moduledoc """
    Result of a successful build.
    """
    defstruct files_written: 0, content_count: 0, elapsed_ms: 0, content_cache: %{}

    @type t :: %__MODULE__{
            files_written: non_neg_integer(),
            content_count: non_neg_integer(),
            elapsed_ms: non_neg_integer(),
            content_cache: map()
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
    verbose = Map.get(config, :verbose, false)
    content_cache = Map.get(config, :content_cache, %{})

    with :ok <- verify_content_dir(config.content_dir),
         {:ok, files} <-
           timed("Discover files", verbose, fn -> discover_files(config.content_dir) end),
         _ <- verbose_log(verbose, "Discovered #{length(files)} files"),
         {:ok, contents, new_cache} <-
           timed("Parse files", verbose, fn ->
             parse_files(files, config.content_dir, config, content_cache)
           end),
         _ <- verbose_log(verbose, "Parsed #{length(contents)} contents"),
         contents <-
           timed_sync("Filter drafts", verbose, fn -> filter_drafts(contents, config.drafts) end),
         _ <- verbose_log(verbose, "#{length(contents)} contents after filtering"),
         contents <- timed_sync("Enrich contents", verbose, fn -> enrich_contents(contents) end),
         {:ok, contents} <-
           timed("Run before_render hooks", verbose, fn ->
             run_hooks(contents, :before_render, config)
           end),
         {:ok, individual_count} <-
           timed("Render pages", verbose, fn -> render_and_write(contents, config) end),
         {:ok, archive_count} <-
           timed("Build archives", verbose, fn -> build_archives(contents, config) end),
         {:ok, index_count} <-
           timed("Build indexes", verbose, fn -> build_type_indexes(contents, config) end),
         {:ok, feed_count} <-
           timed("Generate feeds", verbose, fn -> build_feeds(contents, config) end),
         {:ok, sitemap_count} <-
           timed("Generate sitemap", verbose, fn -> build_sitemap(contents, config) end) do
      timed_sync("Copy theme assets", verbose, fn ->
        Sayfa.Theme.copy_assets(config, config.output_dir)
      end)

      timed_sync("Pagefind indexing", verbose, fn -> run_pagefind(config) end)
      elapsed = System.monotonic_time(:millisecond) - start_time

      verbose_log(verbose, "Build complete in #{elapsed}ms")

      {:ok,
       %Result{
         files_written:
           individual_count + archive_count + index_count + feed_count + sitemap_count,
         content_count: length(contents),
         elapsed_ms: elapsed,
         content_cache: new_cache
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

  # --- Timing & Logging Helpers ---

  defp timed(_label, false, fun), do: fun.()

  defp timed(label, true, fun) do
    start = System.monotonic_time(:millisecond)
    result = fun.()
    elapsed = System.monotonic_time(:millisecond) - start
    Logger.info("[sayfa] #{label} (#{elapsed}ms)")
    result
  end

  defp timed_sync(_label, false, fun), do: fun.()

  defp timed_sync(label, true, fun) do
    start = System.monotonic_time(:millisecond)
    result = fun.()
    elapsed = System.monotonic_time(:millisecond) - start
    Logger.info("[sayfa] #{label} (#{elapsed}ms)")
    result
  end

  defp verbose_log(false, _msg), do: :ok
  defp verbose_log(true, msg), do: Logger.info("[sayfa] #{msg}")

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

  defp parse_files(files, content_dir, config, content_cache) do
    hooks = get_hooks()

    results =
      Enum.reduce_while(files, {[], %{}}, fn file, {acc, cache} ->
        case check_cache(file, content_cache) do
          {:cached, content} ->
            content = classify_content(content, file, content_dir, config)
            mtime = File.stat!(file).mtime
            {:cont, {[content | acc], Map.put(cache, file, {mtime, content})}}

          :miss ->
            with {:ok, raw} <- Content.parse_raw_file(file),
                 {:ok, raw} <- run_hook_list(hooks, :before_parse, raw),
                 {:ok, content} <- Content.from_raw(raw),
                 {:ok, content} <- run_hook_list(hooks, :after_parse, content) do
              content = classify_content(content, file, content_dir, config)
              mtime = File.stat!(file).mtime
              {:cont, {[content | acc], Map.put(cache, file, {mtime, content})}}
            else
              {:error, reason} ->
                {:halt, {:error, {:parse_error, file, reason}}}
            end
        end
      end)

    case results do
      {:error, _} = error -> error
      {contents, cache} -> {:ok, Enum.reverse(contents), cache}
    end
  end

  defp check_cache(_file, cache) when map_size(cache) == 0, do: :miss

  defp check_cache(file, cache) do
    case Map.fetch(cache, file) do
      {:ok, {cached_mtime, content}} ->
        case File.stat(file) do
          {:ok, %{mtime: ^cached_mtime}} -> {:cached, content}
          _ -> :miss
        end

      :error ->
        :miss
    end
  end

  defp classify_content(content, file_path, content_dir, config) do
    relative = Path.relative_to(file_path, content_dir)

    # Detect language from path (e.g., "tr/posts/hello.md" → {:tr, "posts/hello.md"})
    {lang, lang_stripped_path} =
      if map_size(config) > 0 do
        I18n.detect_language(relative, config)
      else
        {content.lang || :en, relative}
      end

    parts = Path.split(lang_stripped_path)

    directory =
      case parts do
        [dir | _rest] when length(parts) > 1 -> dir
        _ -> "pages"
      end

    lang_prefix =
      if map_size(config) > 0 do
        I18n.language_prefix(lang, config)
      else
        ""
      end

    meta =
      content.meta
      |> Map.put("content_type", directory)
      |> Map.put("lang_prefix", lang_prefix)

    meta =
      case ContentType.find_by_directory(directory) do
        nil ->
          meta

        type_mod ->
          meta
          |> Map.put("default_layout", type_mod.default_layout())
          |> Map.put("url_prefix", type_mod.url_prefix())
      end

    %{content | meta: meta, lang: lang}
  end

  defp filter_drafts(contents, true), do: contents

  defp filter_drafts(contents, _) do
    Enum.reject(contents, & &1.draft)
  end

  defp render_and_write(contents, config) do
    hooks = get_hooks()

    results =
      Enum.reduce_while(contents, 0, fn content, count ->
        case render_and_write_one(content, contents, hooks, config) do
          :ok -> {:cont, count + 1}
          {:error, _} = error -> {:halt, error}
        end
      end)

    case results do
      {:error, _} = error -> error
      count -> {:ok, count}
    end
  end

  defp render_and_write_one(content, all_contents, hooks, config) do
    case Template.render_content(content, config: config, all_contents: all_contents) do
      {:ok, html} ->
        case run_hook_list(hooks, :after_render, {content, html}) do
          {:ok, {_content, final_html}} ->
            output_path = output_path_for(content, config.output_dir)
            dir = Path.dirname(output_path)
            File.mkdir_p!(dir)
            File.write!(output_path, final_html)
            :ok

          {:error, _} = error ->
            error
        end

      {:error, _} = error ->
        error
    end
  end

  defp output_path_for(content, output_dir) do
    url_prefix = content.meta["url_prefix"]
    lang_prefix = content.meta["lang_prefix"] || ""

    base_parts =
      case url_prefix do
        nil ->
          content_type = content.meta["content_type"]

          case content_type do
            "pages" -> [content.slug, "index.html"]
            type -> [type, content.slug, "index.html"]
          end

        "" ->
          [content.slug, "index.html"]

        prefix ->
          [prefix, content.slug, "index.html"]
      end

    parts =
      case lang_prefix do
        "" -> [output_dir | base_parts]
        lp -> [output_dir, lp | base_parts]
      end

    Path.join(parts)
  end

  # --- Archives (tags & categories) ---

  defp build_archives(all_contents, config) do
    with {:ok, tag_count} <- build_tag_archives(all_contents, config),
         {:ok, cat_count} <- build_category_archives(all_contents, config) do
      {:ok, tag_count + cat_count}
    end
  end

  defp build_tag_archives(all_contents, config) do
    tag_groups = Content.group_by_tag(all_contents)

    results =
      Enum.reduce_while(tag_groups, 0, fn {tag, items}, count ->
        sorted = Content.sort_by_date(items)
        slug = Slug.slugify(tag)

        case render_and_write_list(
               sorted,
               "Tagged: #{tag}",
               "/tags/#{slug}",
               all_contents,
               config
             ) do
          :ok -> {:cont, count + 1}
          {:error, _} = error -> {:halt, error}
        end
      end)

    case results do
      {:error, _} = error -> error
      count -> {:ok, count}
    end
  end

  defp build_category_archives(all_contents, config) do
    cat_groups = Content.group_by_category(all_contents)

    results =
      Enum.reduce_while(cat_groups, 0, fn {category, items}, count ->
        sorted = Content.sort_by_date(items)
        slug = Slug.slugify(category)

        case render_and_write_list(
               sorted,
               "Category: #{category}",
               "/categories/#{slug}",
               all_contents,
               config
             ) do
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

  defp build_type_indexes(all_contents, config) do
    page_size = Map.get(config, :posts_per_page, 10)

    # Build an index for each content type that has content
    type_groups =
      all_contents
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

        case write_paginated_index(pages, url_prefix, all_contents, config) do
          {:ok, page_count} -> {:cont, total_count + page_count}
          {:error, _} = error -> {:halt, error}
        end
      end)

    case results do
      {:error, _} = error -> error
      count -> {:ok, count}
    end
  end

  defp write_paginated_index(pages, url_prefix, all_contents, config) do
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
               pagination: page,
               all_contents: all_contents
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

  # --- Content Enrichment ---

  defp enrich_contents(contents) do
    Enum.map(contents, fn content ->
      reading_time = ReadingTime.calculate(content.body)
      toc = TOC.extract(content.body)

      meta =
        content.meta
        |> Map.put("reading_time", reading_time)
        |> Map.put("toc", toc)

      %{content | meta: meta}
    end)
  end

  # --- Feeds ---

  defp build_feeds(contents, config) do
    # Group contents by language, ensure default language always has a feed
    lang_groups = Enum.group_by(contents, fn c -> c.meta["lang_prefix"] || "" end)

    # Always generate a main feed for the default language
    lang_groups = Map.put_new(lang_groups, "", [])

    total =
      Enum.reduce(lang_groups, 0, fn {lang_prefix, lang_contents}, count ->
        # Main feed for this language
        main_xml = Feed.generate(lang_contents, config)

        main_path =
          [config.output_dir, lang_prefix, "feed.xml"]
          |> Enum.reject(&(&1 == ""))
          |> Path.join()

        File.mkdir_p!(Path.dirname(main_path))
        File.write!(main_path, main_xml)

        # Per-type feeds for types that have dated content
        type_groups =
          lang_contents
          |> Enum.filter(& &1.date)
          |> Enum.group_by(fn c -> c.meta["content_type"] end)
          |> Enum.reject(fn {type, _} -> type == "pages" end)

        type_count =
          Enum.reduce(type_groups, 0, fn {type, _items}, tc ->
            xml = Feed.generate_for_type(lang_contents, type, config)

            path =
              [config.output_dir, lang_prefix, "feed", "#{type}.xml"]
              |> Enum.reject(&(&1 == ""))
              |> Path.join()

            File.mkdir_p!(Path.dirname(path))
            File.write!(path, xml)
            tc + 1
          end)

        count + 1 + type_count
      end)

    {:ok, total}
  end

  # --- Sitemap ---

  defp build_sitemap(contents, config) do
    # Collect URLs from individual content pages
    content_urls =
      Enum.map(contents, fn content ->
        prefix = content.meta["url_prefix"] || ""
        lang_prefix = content.meta["lang_prefix"] || ""

        base_loc =
          case prefix do
            "" -> "/#{content.slug}/"
            p -> "/#{p}/#{content.slug}/"
          end

        loc =
          case lang_prefix do
            "" -> base_loc
            lp -> "/#{lp}#{base_loc}"
          end

        %{loc: loc, lastmod: content.date}
      end)

    # Collect URLs from tag archives
    tag_urls =
      contents
      |> Content.group_by_tag()
      |> Enum.map(fn {tag, _} ->
        %{loc: "/tags/#{Slug.slugify(tag)}/", lastmod: nil}
      end)

    # Collect URLs from category archives
    cat_urls =
      contents
      |> Content.group_by_category()
      |> Enum.map(fn {cat, _} ->
        %{loc: "/categories/#{Slug.slugify(cat)}/", lastmod: nil}
      end)

    # Collect URLs from content type indexes
    index_urls =
      contents
      |> Enum.group_by(fn c -> c.meta["content_type"] end)
      |> Enum.reject(fn {type, _} -> type == "pages" end)
      |> Enum.map(fn {type, _} ->
        url_prefix =
          case ContentType.find_by_directory(type) do
            nil -> type
            mod -> mod.url_prefix()
          end

        %{loc: "/#{url_prefix}/", lastmod: nil}
      end)

    all_urls = content_urls ++ tag_urls ++ cat_urls ++ index_urls

    xml = Sitemap.generate(all_urls, config)
    path = Path.join(config.output_dir, "sitemap.xml")
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, xml)

    {:ok, 1}
  end

  # --- Pagefind ---

  defp run_pagefind(config) do
    case System.find_executable("pagefind") do
      nil ->
        Logger.info("Pagefind binary not found, skipping search indexing")

      _path ->
        case System.cmd("pagefind", ["--site", config.output_dir], stderr_to_stdout: true) do
          {_output, 0} ->
            Logger.info("Pagefind indexing complete")

          {output, _code} ->
            Logger.warning("Pagefind indexing failed: #{output}")
        end
    end
  end

  # --- Shared List Rendering ---

  defp render_and_write_list(contents, page_title, url_path, all_contents, config) do
    output_path =
      Path.join([config.output_dir, String.trim_leading(url_path, "/"), "index.html"])

    case Template.render_list_page(
           config: config,
           contents: contents,
           page_title: page_title,
           pagination: nil,
           all_contents: all_contents
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

  # --- Hooks ---

  defp get_hooks do
    Application.get_env(:sayfa, :hooks, [])
  end

  defp run_hooks(contents, stage, _config) when is_list(contents) do
    hooks = get_hooks()

    Enum.reduce_while(contents, [], fn content, acc ->
      case run_hook_list(hooks, stage, content) do
        {:ok, updated} -> {:cont, [updated | acc]}
        {:error, _} = error -> {:halt, error}
      end
    end)
    |> case do
      {:error, _} = error -> error
      list -> {:ok, Enum.reverse(list)}
    end
  end

  defp run_hook_list(hooks, stage, value) do
    hooks
    |> Enum.filter(fn mod -> mod.stage() == stage end)
    |> Enum.reduce_while({:ok, value}, fn mod, {:ok, current} ->
      case mod.run(current, %{}) do
        {:ok, updated} -> {:cont, {:ok, updated}}
        {:error, _} = error -> {:halt, error}
      end
    end)
  end
end
