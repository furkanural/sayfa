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

  ## Examples

      # Build with defaults
      {:ok, result} = Sayfa.Builder.build()

      # Build with custom paths
      {:ok, result} = Sayfa.Builder.build(content_dir: "my_content", output_dir: "custom_dist")

      # Clean output directory
      :ok = Sayfa.Builder.clean(output_dir: "custom_dist")

  """

  alias Sayfa.Config
  alias Sayfa.Content
  alias Sayfa.ContentType
  alias Sayfa.Excerpt
  alias Sayfa.Feed
  alias Sayfa.I18n
  alias Sayfa.Pagination
  alias Sayfa.ReadingTime
  alias Sayfa.Sitemap
  alias Sayfa.Tailwind
  alias Sayfa.Template
  alias Sayfa.TOC

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
  - `:output_dir` — output directory (default: `"dist"`)
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
         contents <-
           timed_sync("Auto-link translations", verbose, fn ->
             auto_link_translations(contents, config)
           end),
         contents <-
           timed_sync("Enrich hreflang", verbose, fn -> enrich_hreflang(contents, config) end),
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
      timed_sync("Generate robots.txt", verbose, fn -> build_robots_txt(config) end)

      timed_sync("Copy theme assets", verbose, fn ->
        Sayfa.Theme.copy_assets(config, config.output_dir)
      end)

      timed_sync("Copy static files", verbose, fn -> copy_static_files(config) end)

      timed_sync("TailwindCSS compilation", verbose, fn ->
        Tailwind.compile(config, config.output_dir)
      end)

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

      :ok = Sayfa.Builder.clean(output_dir: "dist")

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

  # --- Static File Copying ---

  defp copy_static_files(config) do
    static_dir = Map.get(config, :static_dir, "static")

    if File.dir?(static_dir) do
      copy_dir_recursive(static_dir, config.output_dir)
    end
  end

  defp copy_dir_recursive(source, dest) do
    source
    |> Path.join("**/*")
    |> Path.wildcard()
    |> Enum.each(fn src_path ->
      relative = Path.relative_to(src_path, source)
      dest_path = Path.join(dest, relative)

      if File.dir?(src_path) do
        File.mkdir_p!(dest_path)
      else
        File.mkdir_p!(Path.dirname(dest_path))
        File.cp!(src_path, dest_path)
      end
    end)
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

  defp parse_files(files, content_dir, config, content_cache) do
    hooks = get_hooks()

    results =
      Enum.reduce_while(files, {[], %{}}, fn file, {acc, cache} ->
        case parse_single_file(file, content_dir, config, content_cache, hooks) do
          {:ok, content} ->
            mtime = File.stat!(file).mtime
            {:cont, {[content | acc], Map.put(cache, file, {mtime, content})}}

          {:error, reason} ->
            {:halt, {:error, {:parse_error, file, reason}}}
        end
      end)

    case results do
      {:error, _} = error -> error
      {contents, cache} -> {:ok, Enum.reverse(contents), cache}
    end
  end

  defp parse_single_file(file, content_dir, config, content_cache, hooks) do
    case check_cache(file, content_cache) do
      {:cached, content} ->
        {:ok, classify_content(content, file, content_dir, config)}

      :miss ->
        with {:ok, raw} <- Content.parse_raw_file(file),
             {:ok, raw} <- run_hook_list(hooks, :before_parse, raw),
             {:ok, content} <- Content.from_raw(raw),
             {:ok, content} <- run_hook_list(hooks, :after_parse, content) do
          {:ok, classify_content(content, file, content_dir, config)}
        end
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
    {lang, lang_stripped_path} = I18n.detect_language(relative, config)

    parts = Path.split(lang_stripped_path)

    directory =
      case parts do
        [dir | _rest] when length(parts) > 1 -> dir
        _ -> "pages"
      end

    lang_prefix = I18n.language_prefix(lang, config)

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
    base_parts = output_base_parts(url_prefix, content)

    parts =
      case lang_prefix do
        "" -> [output_dir | base_parts]
        lp -> [output_dir, lp | base_parts]
      end

    Path.join(parts)
  end

  defp output_base_parts(nil, content) do
    case content.meta["content_type"] do
      "pages" -> slug_path_parts(content.slug)
      type -> [type | slug_path_parts(content.slug)]
    end
  end

  defp output_base_parts("", content), do: slug_path_parts(content.slug)
  defp output_base_parts(prefix, content), do: [prefix | slug_path_parts(content.slug)]

  defp slug_path_parts("index"), do: ["index.html"]
  defp slug_path_parts(slug), do: [slug, "index.html"]

  defp content_sitemap_url(content) do
    %{loc: Content.url(content), lastmod: content.date}
  end

  # --- Archives (tags & categories) ---

  defp build_archives(all_contents, config) do
    with {:ok, tag_count} <- build_tag_archives(all_contents, config),
         {:ok, cat_count} <- build_category_archives(all_contents, config) do
      {:ok, tag_count + cat_count}
    end
  end

  defp build_tag_archives(all_contents, config) do
    tag_lang_groups = Content.group_by_tag_and_lang(all_contents)

    results =
      Enum.reduce_while(tag_lang_groups, 0, fn {{tag, lang_prefix}, items}, count ->
        sorted = Content.sort_by_date(items)
        slug = Slug.slugify(tag)
        lang = lang_from_prefix(lang_prefix, config)

        url_path =
          case lang_prefix do
            "" -> "/tags/#{slug}"
            lp -> "/#{lp}/tags/#{slug}"
          end

        page_title = I18n.t("tagged_title", lang, config, tag: tag)

        archive_alternates =
          build_archive_alternates(tag, "tags", tag_lang_groups, config)

        case render_and_write_list(
               sorted,
               page_title,
               url_path,
               all_contents,
               config,
               lang: lang,
               page_url: "#{url_path}/",
               archive_alternates: archive_alternates
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
    cat_lang_groups = Content.group_by_category_and_lang(all_contents)

    results =
      Enum.reduce_while(cat_lang_groups, 0, fn {{category, lang_prefix}, items}, count ->
        sorted = Content.sort_by_date(items)
        slug = Slug.slugify(category)
        lang = lang_from_prefix(lang_prefix, config)

        url_path =
          case lang_prefix do
            "" -> "/categories/#{slug}"
            lp -> "/#{lp}/categories/#{slug}"
          end

        page_title = I18n.t("category_title", lang, config, category: category)

        archive_alternates =
          build_archive_alternates(category, "categories", cat_lang_groups, config)

        case render_and_write_list(
               sorted,
               page_title,
               url_path,
               all_contents,
               config,
               lang: lang,
               page_url: "#{url_path}/",
               archive_alternates: archive_alternates
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

  defp build_archive_alternates(name, section, lang_groups, config) do
    slug = Slug.slugify(name)

    lang_groups
    |> Enum.filter(fn {{n, _lp}, _items} -> n == name end)
    |> Map.new(fn {{_n, lp}, _items} ->
      lang = lang_from_prefix(lp, config)

      url =
        case lp do
          "" -> "/#{section}/#{slug}/"
          _ -> "/#{lp}/#{section}/#{slug}/"
        end

      {lang, url}
    end)
  end

  # --- Content Type Indexes ---

  defp build_type_indexes(all_contents, config) do
    page_size = Map.get(config, :posts_per_page, 10)

    all_groups =
      Enum.group_by(all_contents, fn c ->
        {c.meta["content_type"], c.meta["lang_prefix"] || ""}
      end)

    # Track which {type, lang_prefix} combos have a user-provided index.md
    user_index_keys =
      all_groups
      |> Enum.filter(fn {{_type, _lang}, items} ->
        Enum.any?(items, fn c -> c.slug == "index" end)
      end)
      |> Enum.map(fn {key, _} -> key end)
      |> MapSet.new()

    # Build an index for each {content_type, lang_prefix} group
    type_lang_groups =
      all_groups
      |> Enum.reject(fn {{type, _lang}, items} ->
        type == "pages" or Enum.any?(items, fn c -> c.slug == "index" end)
      end)
      |> Map.new()

    # Ensure all content_type × language combos have entries (even empty ones)
    # but skip combos where user provided their own index.md
    type_lang_groups =
      ensure_all_type_lang_combos(type_lang_groups, all_contents, config, user_index_keys)

    results =
      Enum.reduce_while(type_lang_groups, 0, fn {{type, lang_prefix}, items}, total_count ->
        case build_type_lang_index(type, lang_prefix, items, page_size, all_contents, config) do
          {:ok, page_count} -> {:cont, total_count + page_count}
          {:error, _} = error -> {:halt, error}
        end
      end)

    case results do
      {:error, _} = error -> error
      count -> {:ok, count}
    end
  end

  defp ensure_all_type_lang_combos(groups, all_contents, config, excluded_keys) do
    # Collect all non-"pages" content types that exist in any language
    content_types =
      all_contents
      |> Enum.map(fn c -> c.meta["content_type"] end)
      |> Enum.reject(&(&1 == "pages"))
      |> Enum.uniq()

    # Compute all language prefixes from configured languages
    lang_prefixes =
      config
      |> I18n.configured_language_codes()
      |> Enum.map(fn lang -> I18n.language_prefix(lang, config) end)

    # Build all valid {type, lang_prefix} keys, excluding user-provided index.md combos
    all_keys =
      for type <- content_types,
          lp <- lang_prefixes,
          not MapSet.member?(excluded_keys, {type, lp}),
          do: {type, lp}

    # Add empty entries for missing combos
    Enum.reduce(all_keys, groups, fn key, acc ->
      Map.put_new(acc, key, [])
    end)
  end

  defp build_type_lang_index(type, lang_prefix, items, page_size, all_contents, config) do
    sorted = Content.sort_by_date(items)

    url_prefix =
      case ContentType.find_by_directory(type) do
        nil -> type
        mod -> mod.url_prefix()
      end

    base_path =
      case lang_prefix do
        "" -> "/#{url_prefix}"
        lp -> "/#{lp}/#{url_prefix}"
      end

    pages = Pagination.paginate(sorted, page_size: page_size, base_path: base_path)

    # For empty content types, still generate a single empty index page
    pages =
      if pages == [] do
        [
          %Pagination.Page{
            items: [],
            page_number: 1,
            page_size: page_size,
            total_items: 0,
            total_pages: 1,
            has_prev: false,
            has_next: false,
            prev_url: nil,
            next_url: nil,
            url: "#{base_path}/"
          }
        ]
      else
        pages
      end

    write_paginated_index(pages, url_prefix, lang_prefix, all_contents, config)
  end

  defp write_paginated_index(pages, url_prefix, lang_prefix, all_contents, config) do
    output_base = index_output_base(config.output_dir, url_prefix, lang_prefix)
    lang = lang_from_prefix(lang_prefix, config)
    page_url = index_page_url(url_prefix, lang_prefix)
    t_fn = I18n.translate_function(lang, config)
    page_title = t_fn.("#{url_prefix}_title")
    archive_alternates = build_type_index_alternates(url_prefix, config)

    results =
      Enum.reduce_while(pages, 0, fn page, count ->
        output_path = index_output_path(output_base, page.page_number)

        case Template.render_list_page(
               config: config,
               contents: page.items,
               page_title: page_title,
               pagination: page,
               content_type: url_prefix,
               all_contents: all_contents,
               lang: lang,
               page_url: page_url,
               archive_alternates: archive_alternates
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

  defp prefixed_path(section, slug, ""), do: "/#{section}/#{slug}"
  defp prefixed_path(section, slug, lp), do: "/#{lp}/#{section}/#{slug}"

  defp index_output_base(output_dir, url_prefix, ""), do: [output_dir, url_prefix]
  defp index_output_base(output_dir, url_prefix, lp), do: [output_dir, lp, url_prefix]

  defp index_output_path(base, 1), do: Path.join(base ++ ["index.html"])
  defp index_output_path(base, n), do: Path.join(base ++ ["page", "#{n}", "index.html"])

  defp lang_from_prefix("", config), do: config.default_lang
  defp lang_from_prefix(lp, _config), do: String.to_atom(lp)

  defp index_page_url(url_prefix, ""), do: "/#{url_prefix}/"
  defp index_page_url(url_prefix, lp), do: "/#{lp}/#{url_prefix}/"

  defp build_type_index_alternates(url_prefix, config) do
    config
    |> I18n.configured_language_codes()
    |> Map.new(fn lang ->
      lp = I18n.language_prefix(lang, config)
      url = index_page_url(url_prefix, lp)
      {lang, url}
    end)
  end

  # --- Content Enrichment ---

  defp enrich_contents(contents) do
    Enum.map(contents, fn content ->
      reading_time = ReadingTime.calculate(content.body)
      toc = TOC.extract(content.body)
      excerpt = Excerpt.extract(content)

      meta =
        content.meta
        |> Map.put("reading_time", reading_time)
        |> Map.put("toc", toc)
        |> Map.put("excerpt", excerpt)

      %{content | meta: meta}
    end)
  end

  # --- Feeds ---

  defp build_feeds(contents, config) do
    # 1. Root feed: ALL content across all languages
    root_xml = Feed.generate(contents, config)
    root_path = Path.join(config.output_dir, "feed.xml")
    File.mkdir_p!(Path.dirname(root_path))
    File.write!(root_path, root_xml)

    # 2. Per-language feeds (only for non-default languages that have content)
    lang_groups =
      contents
      |> Enum.group_by(fn c -> c.meta["lang_prefix"] || "" end)
      |> Enum.reject(fn {lp, _} -> lp == "" end)

    lang_count =
      Enum.reduce(lang_groups, 0, fn {lang_prefix, lang_contents}, count ->
        xml = Feed.generate(lang_contents, config)

        path =
          [config.output_dir, lang_prefix, "feed.xml"]
          |> Enum.reject(&(&1 == ""))
          |> Path.join()

        File.mkdir_p!(Path.dirname(path))
        File.write!(path, xml)
        count + 1
      end)

    # 3. Per-type feeds (across all content)
    type_groups =
      contents
      |> Enum.filter(& &1.date)
      |> Enum.group_by(fn c -> c.meta["content_type"] end)
      |> Enum.reject(fn {type, _} -> type == "pages" end)

    type_count =
      Enum.reduce(type_groups, 0, fn {type, _items}, tc ->
        xml = Feed.generate_for_type(contents, type, config)

        path = Path.join([config.output_dir, "feed", "#{type}.xml"])
        File.mkdir_p!(Path.dirname(path))
        File.write!(path, xml)
        tc + 1
      end)

    {:ok, 1 + lang_count + type_count}
  end

  # --- Sitemap ---

  defp build_sitemap(contents, config) do
    # Collect URLs from individual content pages
    content_urls = Enum.map(contents, &content_sitemap_url/1)

    # Collect URLs from tag archives (language-aware)
    tag_urls =
      contents
      |> Content.group_by_tag_and_lang()
      |> Enum.map(fn {{tag, lang_prefix}, _} ->
        %{loc: prefixed_path("tags", Slug.slugify(tag), lang_prefix), lastmod: nil}
      end)

    # Collect URLs from category archives (language-aware)
    cat_urls =
      contents
      |> Content.group_by_category_and_lang()
      |> Enum.map(fn {{cat, lang_prefix}, _} ->
        %{loc: prefixed_path("categories", Slug.slugify(cat), lang_prefix), lastmod: nil}
      end)

    # Collect URLs from content type indexes (per language)
    index_groups =
      contents
      |> Enum.group_by(fn c -> {c.meta["content_type"], c.meta["lang_prefix"] || ""} end)
      |> Enum.reject(fn {{type, _}, _} -> type == "pages" end)
      |> Map.new()

    index_groups = ensure_all_type_lang_combos(index_groups, contents, config, MapSet.new())

    index_urls =
      Enum.map(index_groups, fn {{type, lang_prefix}, _} ->
        url_prefix =
          case ContentType.find_by_directory(type) do
            nil -> type
            mod -> mod.url_prefix()
          end

        loc =
          case lang_prefix do
            "" -> "/#{url_prefix}"
            lp -> "/#{lp}/#{url_prefix}"
          end

        %{loc: loc, lastmod: nil}
      end)

    all_urls = content_urls ++ tag_urls ++ cat_urls ++ index_urls

    xml = Sitemap.generate(all_urls, config)
    path = Path.join(config.output_dir, "sitemap.xml")
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, xml)

    {:ok, 1}
  end

  # --- robots.txt ---

  defp build_robots_txt(config) do
    base_url = String.trim_trailing(config.base_url, "/")

    content = """
    User-agent: *
    Allow: /

    Sitemap: #{base_url}/sitemap.xml
    """

    path = Path.join(config.output_dir, "robots.txt")
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, content)
  end

  # --- Auto-link translations ---

  defp auto_link_translations(contents, config) do
    default_lang = Map.get(config, :default_lang, :en)

    groups =
      Enum.group_by(contents, fn c -> {c.meta["content_type"], c.slug} end)

    translation_map =
      groups
      |> Enum.filter(&multilingual_group?(&1, default_lang))
      |> Enum.flat_map(fn {_key, group_items} ->
        build_translation_entries(group_items, default_lang)
      end)
      |> Map.new()

    Enum.map(contents, fn content ->
      apply_auto_translation(content, translation_map, default_lang)
    end)
  end

  defp multilingual_group?({_key, items}, default_lang) do
    items
    |> Enum.map(fn c -> c.lang || default_lang end)
    |> Enum.uniq()
    |> length()
    |> Kernel.>(1)
  end

  defp build_translation_entries(group_items, default_lang) do
    Enum.map(group_items, fn c ->
      own_lang = c.lang || default_lang

      translations =
        group_items
        |> Enum.reject(fn other -> (other.lang || default_lang) == own_lang end)
        |> Map.new(fn other -> {to_string(other.lang || default_lang), other.slug} end)

      identity = {c.meta["content_type"], own_lang, c.slug}
      {identity, translations}
    end)
  end

  defp apply_auto_translation(content, translation_map, default_lang) do
    case content.meta["translations"] do
      existing when is_map(existing) and map_size(existing) > 0 ->
        content

      _ ->
        identity = {content.meta["content_type"], content.lang || default_lang, content.slug}

        case Map.get(translation_map, identity) do
          nil -> content
          translations -> %{content | meta: Map.put(content.meta, "translations", translations)}
        end
    end
  end

  # --- hreflang enrichment ---

  defp enrich_hreflang(contents, config) do
    default_lang = Map.get(config, :default_lang, :en)

    # Build lookup: {content_type, lang, slug} => content
    lookup =
      Map.new(contents, fn c ->
        lang = c.lang || default_lang
        content_type = c.meta["content_type"]
        {{content_type, lang, c.slug}, c}
      end)

    Enum.map(contents, fn content ->
      alternates = resolve_hreflang_alternates(content, lookup, default_lang)

      if alternates do
        %{content | meta: Map.put(content.meta, "hreflang_alternates", alternates)}
      else
        content
      end
    end)
  end

  defp resolve_hreflang_alternates(content, lookup, default_lang) do
    case content.meta["translations"] do
      map when is_map(map) and map_size(map) > 0 ->
        own_lang = content.lang || default_lang
        self_entry = {to_string(own_lang), Content.url(content)}
        other_entries = resolve_translation_entries(map, content.meta["content_type"], lookup)
        [self_entry | other_entries]

      _ ->
        nil
    end
  end

  defp resolve_translation_entries(translations, content_type, lookup) do
    Enum.flat_map(translations, fn {lang_str, slug} ->
      lang_atom = String.to_atom(lang_str)

      case Map.get(lookup, {content_type, lang_atom, slug}) do
        %Content{} = translated -> [{lang_str, Content.url(translated)}]
        nil -> []
      end
    end)
  end

  # --- Shared List Rendering ---

  defp render_and_write_list(contents, page_title, url_path, all_contents, config, opts) do
    lang = Keyword.get(opts, :lang, config.default_lang)
    page_url = Keyword.get(opts, :page_url, url_path <> "/")
    archive_alternates = Keyword.get(opts, :archive_alternates)

    output_path =
      Path.join([config.output_dir, String.trim_leading(url_path, "/"), "index.html"])

    case Template.render_list_page(
           config: config,
           contents: contents,
           page_title: page_title,
           pagination: nil,
           content_type: nil,
           all_contents: all_contents,
           lang: lang,
           page_url: page_url,
           archive_alternates: archive_alternates
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
