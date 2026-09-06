defmodule Sayfa.MarkdownMirror do
  @moduledoc """
  Generates clean Markdown mirrors of content pages for LLM/AI consumers.

  For every content page (e.g. `/articles/hello`), Sayfa can emit a sibling
  Markdown file (e.g. `/articles/hello.md`) containing the same content in its
  original Markdown form, as recommended by the [llms.txt](https://llmstxt.org/)
  convention. The HTML page advertises its mirror via
  `<link rel="alternate" type="text/markdown">` (see `Sayfa.SEO.meta_tags/3`).

  Mirrors are enabled by default and can be disabled with
  `config :sayfa, markdown_mirrors: false`.
  """

  alias Sayfa.Content

  @doc """
  Returns whether Markdown mirrors are enabled (default: `true`).

  ## Examples

      iex> Sayfa.MarkdownMirror.enabled?(%{})
      true

      iex> Sayfa.MarkdownMirror.enabled?(%{markdown_mirrors: false})
      false

  """
  @spec enabled?(map()) :: boolean()
  def enabled?(config), do: Map.get(config, :markdown_mirrors, true)

  @doc """
  Renders the Markdown mirror for a content item.

  The output is the original Markdown body preceded by an `# title` heading
  and an italic metadata line with the publication date, tags, and canonical
  URL (each part omitted when unavailable).

  ## Examples

      iex> content = %Sayfa.Content{
      ...>   title: "Hello",
      ...>   body: "<p>Hi</p>",
      ...>   slug: "hello",
      ...>   date: ~D[2026-09-06],
      ...>   tags: ["elixir"],
      ...>   meta: %{"body_markdown" => "Some *markdown* body", "url_prefix" => "articles", "lang_prefix" => ""}
      ...> }
      iex> Sayfa.MarkdownMirror.render(content, %{base_url: "https://example.com"})
      "# Hello\\n\\n*Published 2026-09-06 · Tags: elixir · https://example.com/articles/hello*\\n\\nSome *markdown* body\\n"

  """
  @spec render(Content.t(), map()) :: String.t()
  def render(%Content{} = content, config) do
    body = content.meta["body_markdown"] || ""

    case meta_line(content, config) do
      nil -> "# #{content.title}\n\n#{body}\n"
      line -> "# #{content.title}\n\n#{line}\n\n#{body}\n"
    end
  end

  @doc """
  Returns the output file path for a content item's Markdown mirror,
  given the path of its rendered HTML file.

  The mirror is written as a sibling of the HTML page's directory:
  `articles/hello/index.html` → `articles/hello.md`.

  Returns `nil` for content without a mirror — currently the `"index"`
  slug (home/index pages).

  ## Examples

      iex> content = %Sayfa.Content{title: "T", body: "", slug: "hello"}
      iex> Sayfa.MarkdownMirror.path(content, "output/articles/hello/index.html")
      "output/articles/hello.md"

      iex> content = %Sayfa.Content{title: "T", body: "", slug: "index"}
      iex> Sayfa.MarkdownMirror.path(content, "output/index.html")
      nil

  """
  @spec path(Content.t(), String.t()) :: String.t() | nil
  def path(%Content{slug: "index"}, _html_path), do: nil

  def path(%Content{slug: slug}, html_path) do
    html_path
    |> Path.dirname()
    |> Path.dirname()
    |> Path.join("#{slug}.md")
  end

  @doc """
  Returns the URL path of a content item's Markdown mirror, or `nil`
  when the content has no mirror.

  ## Examples

      iex> content = %Sayfa.Content{title: "T", body: "", slug: "hello", meta: %{"url_prefix" => "articles", "lang_prefix" => ""}}
      iex> Sayfa.MarkdownMirror.url(content)
      "/articles/hello.md"

      iex> content = %Sayfa.Content{title: "T", body: "", slug: "index", meta: %{"url_prefix" => "", "lang_prefix" => ""}}
      iex> Sayfa.MarkdownMirror.url(content)
      nil

  """
  @spec url(Content.t()) :: String.t() | nil
  def url(%Content{slug: "index"}), do: nil
  def url(%Content{} = content), do: Content.url(content) <> ".md"

  defp meta_line(content, config) do
    parts =
      [
        date_part(content),
        tags_part(content),
        url_part(content, config)
      ]
      |> Enum.reject(&is_nil/1)

    case parts do
      [] -> nil
      _ -> "*#{Enum.join(parts, " · ")}*"
    end
  end

  defp date_part(%Content{date: nil}), do: nil
  defp date_part(%Content{date: date}), do: "Published #{date}"

  defp tags_part(%Content{tags: []}), do: nil
  defp tags_part(%Content{tags: tags}), do: "Tags: #{Enum.join(tags, ", ")}"

  defp url_part(content, config) do
    case Map.get(config, :base_url) do
      nil -> nil
      _ -> Sayfa.SEO.content_url(content, config)
    end
  end
end
