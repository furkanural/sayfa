defmodule Sayfa.SEO do
  @moduledoc """
  Generates SEO meta tags for HTML pages.

  Produces Open Graph, Twitter Card, description, and canonical URL tags.
  Designed to be called from the base template:

      <%= Sayfa.SEO.meta_tags(@content, @site) %>

  """

  alias Sayfa.Content

  @doc """
  Generates HTML meta tags for SEO.

  When `content` is a `%Content{}`, generates tags specific to that content.
  When `content` is `nil` (e.g., list pages), uses site-level defaults.

  ## Examples

      iex> config = %{title: "My Site", base_url: "https://example.com", description: "A blog"}
      iex> content = %Sayfa.Content{title: "Hello", body: "<p>World</p>", slug: "hello", meta: %{"url_prefix" => "posts"}}
      iex> html = Sayfa.SEO.meta_tags(content, config)
      iex> html =~ ~s(og:title)
      true
      iex> html =~ ~s(canonical)
      true

  """
  @spec meta_tags(Content.t() | nil, map()) :: String.t()
  def meta_tags(%Content{} = content, config) do
    description = content_description(content)
    url = content_url(content, config)

    tags = [
      meta("description", description),
      meta("og:title", content.title),
      meta("og:description", description),
      meta("og:url", url),
      meta("og:type", "article"),
      meta("og:site_name", config.title),
      meta("twitter:card", "summary"),
      meta("twitter:title", content.title),
      meta("twitter:description", description),
      link_tag("canonical", url)
    ]

    tags
    |> maybe_add_image(content)
    |> Enum.join("\n")
  end

  def meta_tags(nil, config) do
    description = Map.get(config, :description, "")

    [
      meta("description", description),
      meta("og:title", config.title),
      meta("og:description", description),
      meta("og:type", "website"),
      meta("og:site_name", config.title),
      meta("twitter:card", "summary"),
      meta("twitter:title", config.title),
      meta("twitter:description", description)
    ]
    |> Enum.join("\n")
  end

  @doc """
  Builds the full URL for a content item.

  ## Examples

      iex> content = %Sayfa.Content{title: "T", body: "", slug: "hello", meta: %{"url_prefix" => "posts"}}
      iex> config = %{base_url: "https://example.com"}
      iex> Sayfa.SEO.content_url(content, config)
      "https://example.com/posts/hello"

      iex> content = %Sayfa.Content{title: "T", body: "", slug: "about", meta: %{"url_prefix" => ""}}
      iex> config = %{base_url: "https://example.com"}
      iex> Sayfa.SEO.content_url(content, config)
      "https://example.com/about"

  """
  @spec content_url(Content.t(), map()) :: String.t()
  def content_url(%Content{} = content, config) do
    base = String.trim_trailing(config.base_url, "/")
    prefix = content.meta["url_prefix"] || ""

    case {prefix, content.slug} do
      {"", "index"} -> base
      {"", slug} -> "#{base}/#{slug}"
      {p, "index"} -> "#{base}/#{p}"
      {p, slug} -> "#{base}/#{p}/#{slug}"
    end
  end

  defp content_description(%Content{meta: %{"description" => desc}}) when is_binary(desc) do
    desc
  end

  defp content_description(%Content{body: body}) do
    body
    |> then(&Regex.replace(~r/<[^>]*>/, &1, ""))
    |> then(&Regex.replace(~r/\s+/, &1, " "))
    |> String.trim()
    |> String.slice(0, 160)
  end

  defp meta(name, content) do
    safe_content = escape_attr(content)

    if String.starts_with?(name, "og:") or String.starts_with?(name, "twitter:") do
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

  defp escape_attr(value) do
    value
    |> String.replace("&", "&amp;")
    |> String.replace("\"", "&quot;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
  end
end
