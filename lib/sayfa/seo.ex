defmodule Sayfa.SEO do
  @moduledoc """
  Generates SEO meta tags for HTML pages.

  Produces Open Graph, Twitter Card, description, canonical URL tags,
  JSON-LD structured data, and hreflang alternate links.
  Designed to be called from the base template:

      <%= Sayfa.SEO.meta_tags(@content, @site) %>
      <%= Sayfa.SEO.json_ld(assigns[:content], @site) %>
      <%= Sayfa.SEO.hreflang_tags(assigns[:content], @site, assigns[:archive_alternates]) %>

  """

  alias Sayfa.Content

  @article_types ~w(articles notes)

  @doc """
  Generates HTML meta tags for SEO.

  When `content` is a `%Content{}`, generates tags specific to that content.
  When `content` is `nil` (e.g., list pages), uses site-level defaults.

  ## Examples

      iex> config = %{title: "My Site", base_url: "https://example.com", description: "A blog"}
      iex> content = %Sayfa.Content{title: "Hello", body: "<p>World</p>", slug: "hello", meta: %{"url_prefix" => "articles"}}
      iex> html = Sayfa.SEO.meta_tags(content, config)
      iex> html =~ ~s(og:title)
      true
      iex> html =~ ~s(canonical)
      true

  """
  @spec meta_tags(Content.t() | nil, map(), String.t() | nil) :: String.t()
  def meta_tags(content, config, page_url \\ nil)

  def meta_tags(%Content{} = content, config, _page_url) do
    description = content_description(content)
    url = content_url(content, config)
    twitter_card_type = if content.meta["image"], do: "summary_large_image", else: "summary"
    locale = og_locale(content)

    tags = [
      meta("description", description),
      meta("og:title", content.title),
      meta("og:description", description),
      meta("og:url", url),
      meta("og:type", "article"),
      meta("og:site_name", config.title),
      meta("og:locale", locale),
      meta("twitter:card", twitter_card_type),
      meta("twitter:title", content.title),
      meta("twitter:description", description),
      link_tag("canonical", url)
    ]

    tags
    |> maybe_add_image(content)
    |> maybe_add_article_tags(content, config)
    |> maybe_add_og_updated_time(content)
    |> maybe_add_twitter_site(config)
    |> maybe_add_twitter_creator(content, config)
    |> Enum.join("\n")
  end

  def meta_tags(nil, config, page_url) do
    description = Map.get(config, :description, "")
    locale = og_locale(nil)

    tags = [
      meta("description", description),
      meta("og:title", config.title),
      meta("og:description", description),
      meta("og:type", "website"),
      meta("og:site_name", config.title),
      meta("og:locale", locale),
      meta("twitter:card", "summary"),
      meta("twitter:title", config.title),
      meta("twitter:description", description)
    ]

    tags = if page_url, do: tags ++ [link_tag("canonical", page_url)], else: tags

    tags
    |> maybe_add_twitter_site(config)
    |> Enum.join("\n")
  end

  @doc """
  Generates a JSON-LD structured data script tag.

  For articles/notes, generates a `BlogPosting` schema. For pages, generates a
  `WebPage` schema. For nil (list pages), generates a `WebSite` schema.

  ## Examples

      iex> config = %{title: "My Site", base_url: "https://example.com", author: "Jane"}
      iex> content = %Sayfa.Content{title: "Hello", body: "<p>World</p>", slug: "hello", date: ~D[2024-01-15], meta: %{"content_type" => "articles", "url_prefix" => "articles", "lang_prefix" => ""}}
      iex> html = Sayfa.SEO.json_ld(content, config)
      iex> html =~ "BlogPosting"
      true
      iex> html =~ "application/ld+json"
      true

  """
  @spec json_ld(Content.t() | nil, map()) :: String.t()
  def json_ld(%Content{} = content, config) do
    content.meta["content_type"]
    |> content_json_ld(content, config)
    |> render_json_ld()
  end

  def json_ld(nil, config) do
    %{
      "@context" => "https://schema.org",
      "@type" => "WebSite",
      "name" => config.title,
      "url" => String.trim_trailing(config.base_url, "/")
    }
    |> maybe_put("description", Map.get(config, :description))
    |> render_json_ld()
  end

  @doc """
  Generates hreflang alternate link tags for multilingual content.

  Reads `content.meta["hreflang_alternates"]` (a list of `{lang, path}` tuples)
  and renders `<link rel="alternate" hreflang="..." href="...">` for each.
  When multiple alternates exist, also adds an `x-default` pointing to the
  content's own URL.

  Returns an empty string when content is nil or has no alternates.

  ## Examples

      iex> config = %{base_url: "https://example.com"}
      iex> content = %Sayfa.Content{title: "T", body: "", slug: "hello", meta: %{"url_prefix" => "articles", "lang_prefix" => "", "hreflang_alternates" => [{"en", "/articles/hello"}, {"tr", "/tr/articles/merhaba"}]}}
      iex> html = Sayfa.SEO.hreflang_tags(content, config)
      iex> html =~ ~s(hreflang="en")
      true
      iex> html =~ ~s(hreflang="tr")
      true
      iex> html =~ ~s(hreflang="x-default")
      true

  """
  @spec hreflang_tags(Content.t() | nil, map(), map() | nil) :: String.t()
  def hreflang_tags(content, config, archive_alternates \\ nil)

  def hreflang_tags(
        %Content{meta: %{"hreflang_alternates" => alternates}},
        config,
        _archive_alternates
      )
      when is_list(alternates) and alternates != [] do
    base = String.trim_trailing(config.base_url, "/")

    tags =
      Enum.map(alternates, fn {lang, path} ->
        ~s(<link rel="alternate" hreflang="#{escape_attr(lang)}" href="#{escape_attr(base <> path)}">)
      end)

    tags =
      if length(alternates) > 1 do
        default_lang = Map.get(config, :default_lang, :en)

        case List.keyfind(alternates, to_string(default_lang), 0) do
          {_lang, default_path} ->
            tags ++
              [
                ~s(<link rel="alternate" hreflang="x-default" href="#{escape_attr(base <> default_path)}">)
              ]

          nil ->
            tags
        end
      else
        tags
      end

    Enum.join(tags, "\n")
  end

  def hreflang_tags(nil, config, archive_alternates)
      when is_map(archive_alternates) and map_size(archive_alternates) > 0 do
    base = String.trim_trailing(config.base_url, "/")

    tags =
      Enum.map(archive_alternates, fn {lang, url} ->
        lang_str = to_string(lang)

        ~s(<link rel="alternate" hreflang="#{escape_attr(lang_str)}" href="#{escape_attr(base <> url)}">)
      end)

    tags =
      if map_size(archive_alternates) > 1 do
        default_lang = Map.get(config, :default_lang, :en)
        default_url = Map.get(archive_alternates, default_lang)

        if default_url do
          tags ++
            [
              ~s(<link rel="alternate" hreflang="x-default" href="#{escape_attr(base <> default_url)}">)
            ]
        else
          tags
        end
      else
        tags
      end

    Enum.join(tags, "\n")
  end

  def hreflang_tags(_content, _config, _archive_alternates), do: ""

  @doc """
  Generates favicon link tags for the HTML head.

  Returns link tags for favicon.ico, favicon.svg, apple-touch-icon,
  and web app manifest.

  ## Examples

      iex> Sayfa.SEO.favicon_tags() =~ ~s(rel="icon")
      true

  """
  @spec favicon_tags() :: String.t()
  def favicon_tags do
    [
      ~s(<link rel="icon" href="/favicon.ico" sizes="32x32">),
      ~s(<link rel="icon" href="/favicon.svg" type="image/svg+xml">),
      ~s(<link rel="apple-touch-icon" href="/apple-touch-icon.png">),
      ~s(<link rel="manifest" href="/site.webmanifest">)
    ]
    |> Enum.join("\n")
  end

  @doc """
  Builds the full URL for a content item.

  ## Examples

      iex> content = %Sayfa.Content{title: "T", body: "", slug: "hello", meta: %{"url_prefix" => "articles", "lang_prefix" => ""}}
      iex> config = %{base_url: "https://example.com"}
      iex> Sayfa.SEO.content_url(content, config)
      "https://example.com/articles/hello"

      iex> content = %Sayfa.Content{title: "T", body: "", slug: "about", meta: %{"url_prefix" => "", "lang_prefix" => ""}}
      iex> config = %{base_url: "https://example.com"}
      iex> Sayfa.SEO.content_url(content, config)
      "https://example.com/about"

  """
  @spec content_url(Content.t(), map()) :: String.t()
  def content_url(%Content{} = content, config) do
    base = String.trim_trailing(config.base_url, "/")
    base <> Content.url(content)
  end

  # --- Private Helpers ---

  defp content_description(%Content{meta: %{"description" => desc}}) when is_binary(desc) do
    desc
  end

  defp content_description(%Content{body: body}) do
    body
    |> then(&Regex.replace(~r/<[^>]*>/, &1, ""))
    |> then(&Regex.replace(~r/\s+/, &1, " "))
    |> String.trim()
    |> String.slice(0, Sayfa.Config.get(:seo_description_length, 160))
  end

  defp meta(name, content) do
    safe_content = escape_attr(content)

    if String.starts_with?(name, "og:") or String.starts_with?(name, "twitter:") or
         String.starts_with?(name, "article:") do
      ~s(<meta property="#{name}" content="#{safe_content}">)
    else
      ~s(<meta name="#{name}" content="#{safe_content}">)
    end
  end

  defp link_tag(rel, href) do
    ~s(<link rel="#{rel}" href="#{escape_attr(href)}">)
  end

  defp maybe_add_image(tags, %Content{meta: %{"image" => image}}) when is_binary(image) do
    tags ++ [meta("og:image", image), meta("twitter:image", image)]
  end

  defp maybe_add_image(tags, _content), do: tags

  defp maybe_add_article_tags(tags, %Content{} = content, config) do
    content_type = content.meta["content_type"]

    if content_type in @article_types do
      article_tags =
        []
        |> maybe_add_date_tag("article:published_time", content.date)
        |> maybe_add_date_tag("article:modified_time", content.meta["updated"])
        |> maybe_add_author_tag(config)
        |> add_category_tags(content.categories)
        |> add_tag_tags(content.tags)

      tags ++ article_tags
    else
      tags
    end
  end

  defp maybe_add_date_tag(tags, _name, nil), do: tags

  defp maybe_add_date_tag(tags, name, %Date{} = date) do
    tags ++ [meta(name, Date.to_iso8601(date))]
  end

  defp maybe_add_date_tag(tags, name, date) when is_binary(date) do
    tags ++ [meta(name, date)]
  end

  defp maybe_add_author_tag(tags, %{author: author}) when is_binary(author) do
    tags ++ [meta("article:author", author)]
  end

  defp maybe_add_author_tag(tags, _config), do: tags

  defp add_category_tags(tags, []), do: tags

  defp add_category_tags(tags, categories) do
    cat_metas = Enum.map(categories, fn cat -> meta("article:section", cat) end)
    tags ++ cat_metas
  end

  defp add_tag_tags(tags, []), do: tags

  defp add_tag_tags(tags, content_tags) do
    tag_metas = Enum.map(content_tags, fn tag -> meta("article:tag", tag) end)
    tags ++ tag_metas
  end

  defp og_locale(%Content{lang: lang}) when not is_nil(lang) do
    to_string(lang) |> locale_from_lang()
  end

  defp og_locale(_nil) do
    default_lang = Sayfa.Config.get(:default_lang, :en)
    locale_from_lang(to_string(default_lang))
  end

  defp locale_from_lang("en"), do: "en_US"
  defp locale_from_lang("tr"), do: "tr_TR"
  defp locale_from_lang(lang), do: String.replace(lang, "-", "_") |> String.downcase()

  defp maybe_add_og_updated_time(tags, %Content{meta: %{"updated" => updated}})
       when not is_nil(updated) do
    tags ++ [meta("og:updated_time", format_date(updated))]
  end

  defp maybe_add_og_updated_time(tags, _content), do: tags

  defp maybe_add_twitter_site(tags, %{twitter_handle: handle}) when is_binary(handle) do
    tags ++ [meta("twitter:site", handle)]
  end

  defp maybe_add_twitter_site(tags, _config), do: tags

  defp maybe_add_twitter_creator(tags, %Content{meta: %{"author" => author}}, _config)
       when is_binary(author) do
    tags ++ [meta("twitter:creator", author)]
  end

  defp maybe_add_twitter_creator(tags, _content, %{author: author}) when is_binary(author) do
    tags ++ [meta("twitter:creator", author)]
  end

  defp maybe_add_twitter_creator(tags, _content, _config), do: tags

  # --- JSON-LD Helpers ---

  defp content_json_ld(content_type, content, config) when content_type in @article_types do
    base = String.trim_trailing(config.base_url, "/")

    %{
      "@context" => "https://schema.org",
      "@type" => "BlogPosting",
      "headline" => content.title,
      "url" => base <> Content.url(content)
    }
    |> maybe_put("description", content_description(content))
    |> maybe_put("datePublished", format_date(content.date))
    |> maybe_put("dateModified", format_date(content.meta["updated"]))
    |> maybe_put_author(config)
    |> maybe_put_keywords(content.tags)
  end

  defp content_json_ld(_content_type, content, config) do
    base = String.trim_trailing(config.base_url, "/")

    %{
      "@context" => "https://schema.org",
      "@type" => "WebPage",
      "name" => content.title,
      "url" => base <> Content.url(content)
    }
    |> maybe_put("description", content_description(content))
  end

  defp render_json_ld(data) do
    json = JSON.encode!(data)
    ~s(<script type="application/ld+json">#{json}</script>)
  end

  defp format_date(nil), do: nil
  defp format_date(%Date{} = date), do: Date.to_iso8601(date)
  defp format_date(date) when is_binary(date), do: date

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, _key, ""), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp maybe_put_author(map, %{author: author}) when is_binary(author) do
    Map.put(map, "author", %{"@type" => "Person", "name" => author})
  end

  defp maybe_put_author(map, _config), do: map

  defp maybe_put_keywords(map, []), do: map
  defp maybe_put_keywords(map, tags), do: Map.put(map, "keywords", Enum.join(tags, ", "))

  defp escape_attr(value) do
    value
    |> String.replace("&", "&amp;")
    |> String.replace("\"", "&quot;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
  end
end
