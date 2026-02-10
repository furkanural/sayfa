defmodule Sayfa.TOC do
  @moduledoc """
  Extracts table of contents from rendered HTML.

  Parses heading elements (h2-h6) from HTML and returns a list of
  TOC entries with level, text, and anchor ID. Skips h1 as that
  is typically the page title.

  Requires headings to have anchor IDs (enabled via MDEx `header_ids` option).

  ## Examples

      iex> html = ~s(<h2><a href="#intro" aria-hidden="true" class="anchor" id="intro"></a>Introduction</h2>)
      iex> Sayfa.TOC.extract(html)
      [%{level: 2, text: "Introduction", id: "intro"}]

  """

  @doc """
  Extracts table of contents entries from HTML.

  Returns a list of maps with `:level`, `:text`, and `:id` keys.
  Only extracts h2-h6 headings (h1 is skipped as the page title).
  Returns an empty list if no headings are found.

  ## Examples

      iex> html = ~s(<h2><a href="#intro" aria-hidden="true" class="anchor" id="intro"></a>Introduction</h2>)
      iex> Sayfa.TOC.extract(html)
      [%{level: 2, text: "Introduction", id: "intro"}]

      iex> Sayfa.TOC.extract("<p>No headings here</p>")
      []

      iex> Sayfa.TOC.extract("")
      []

  """
  @spec extract(String.t()) :: [%{level: integer(), text: String.t(), id: String.t()}]
  def extract(html) when is_binary(html) do
    ~r/<h([2-6])><a [^>]*id="([^"]*)"[^>]*><\/a>(.+?)<\/h\1>/s
    |> Regex.scan(html)
    |> Enum.map(fn [_, level, id, text] ->
      %{
        level: String.to_integer(level),
        text: strip_inline_tags(text),
        id: id
      }
    end)
  end

  defp strip_inline_tags(text) do
    Regex.replace(~r/<[^>]*>/, text, "")
  end
end
