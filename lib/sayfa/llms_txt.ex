defmodule Sayfa.LlmsTxt do
  @moduledoc """
  Generates the site's `/llms.txt` index for LLM/AI consumers.

  Following the [llms.txt](https://llmstxt.org/) convention, the file is a
  Markdown document with the site name as an H1, a blockquote summary, and one
  H2 section per content type listing links to each page's Markdown mirror
  (see `Sayfa.MarkdownMirror`).

  The file is written to the output directory root as `llms.txt` whenever
  Markdown mirrors are enabled (see `Sayfa.MarkdownMirror.enabled?/1`).
  """

  alias Sayfa.Content
  alias Sayfa.MarkdownMirror

  @section_order ~w(articles notes projects talks pages)

  @doc """
  Generates the `llms.txt` content for a list of contents.

  Contents without a Markdown mirror (e.g. the `"index"` slug) are skipped.
  Links point at the absolute mirror URL when `:base_url` is configured,
  otherwise at the relative path.

  ## Examples

      iex> contents = [
      ...>   %Sayfa.Content{
      ...>     title: "Hello",
      ...>     body: "",
      ...>     slug: "hello",
      ...>     date: ~D[2026-09-06],
      ...>     meta: %{"content_type" => "articles", "url_prefix" => "articles", "lang_prefix" => "", "description" => "First post"}
      ...>   }
      ...> ]
      iex> Sayfa.LlmsTxt.generate(contents, %{title: "My Blog", description: "Notes on Elixir", base_url: "https://example.com"})
      "# My Blog\\n\\n> Notes on Elixir\\n\\n## Articles\\n\\n- [Hello](https://example.com/articles/hello.md): First post\\n\\n"

  """
  @spec generate([Content.t()], map()) :: String.t()
  def generate(contents, config) do
    header(config) <> sections(contents, config)
  end

  defp header(config) do
    title = Map.get(config, :title, "Site")

    case Map.get(config, :description) do
      nil -> "# #{title}\n\n"
      "" -> "# #{title}\n\n"
      description -> "# #{title}\n\n> #{description}\n\n"
    end
  end

  defp sections(contents, config) do
    contents
    |> Enum.filter(&MarkdownMirror.url/1)
    |> Enum.group_by(& &1.meta["content_type"])
    |> Enum.sort_by(fn {type, _} -> section_sort_key(type) end)
    |> Enum.map_join("", fn {type, items} -> section(type, items, config) end)
  end

  defp section_sort_key(type) do
    case Enum.find_index(@section_order, &(&1 == type)) do
      nil -> {length(@section_order), to_string(type)}
      index -> {index, ""}
    end
  end

  defp section(type, items, config) do
    entries =
      items
      |> Enum.sort_by(&(&1.date || ~D[0000-01-01]), {:desc, Date})
      |> Enum.map_join("\n", &entry(&1, config))

    "## #{section_title(type)}\n\n#{entries}\n\n"
  end

  defp section_title(type) do
    type |> to_string() |> String.capitalize()
  end

  defp entry(content, config) do
    url = absolute_mirror_url(content, config)

    case content.meta["description"] do
      desc when is_binary(desc) and desc != "" -> "- [#{content.title}](#{url}): #{desc}"
      _ -> "- [#{content.title}](#{url})"
    end
  end

  defp absolute_mirror_url(content, config) do
    case Map.get(config, :base_url) do
      nil ->
        MarkdownMirror.url(content)

      base_url ->
        String.trim_trailing(base_url, "/") <> MarkdownMirror.url(content)
    end
  end
end
