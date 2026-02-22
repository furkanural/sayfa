defmodule Sayfa.Excerpt do
  @moduledoc """
  Excerpt generation from content body.

  Generates short summaries for use in list pages, feeds, and SEO.
  Supports both manual excerpts (via `excerpt:` front matter) and
  automatic generation from the first paragraph.

  ## Examples

      iex> content = %Sayfa.Content{body: "<p>First paragraph.</p><p>Second.</p>", meta: %{}}
      iex> Sayfa.Excerpt.extract(content)
      "First paragraph."

      iex> content = %Sayfa.Content{body: "Long text...", meta: %{"excerpt" => "Custom excerpt"}}
      iex> Sayfa.Excerpt.extract(content)
      "Custom excerpt"

  """

  @default_length 160

  @doc """
  Extracts an excerpt from content.

  Priority order:
  1. `excerpt` field in content.meta
  2. First paragraph from HTML body (stripped of tags)
  3. Truncated body (if no paragraph breaks)

  ## Options

  - `:length` - Maximum length of excerpt (default: #{@default_length})

  ## Examples

      iex> content = %Sayfa.Content{body: "<p>Hello world</p>", meta: %{}}
      iex> Sayfa.Excerpt.extract(content)
      "Hello world"

  """
  @spec extract(Sayfa.Content.t(), keyword()) :: String.t()
  def extract(content, opts \\ []) do
    cond do
      manual = content.meta["excerpt"] ->
        truncate(manual, opts)

      auto = first_paragraph(content.body) ->
        truncate(auto, opts)

      true ->
        truncate(strip_html(content.body), opts)
    end
  end

  defp first_paragraph(html) when is_binary(html) do
    case Regex.run(~r/<p[^>]*>(.*?)<\/p>/s, html) do
      [_, text] -> strip_html(text)
      nil -> nil
    end
  end

  defp first_paragraph(_), do: nil

  defp strip_html(html) when is_binary(html) do
    html
    |> String.replace(~r/<[^>]+>/, "")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end

  defp strip_html(_), do: ""

  defp truncate(text, opts) when is_binary(text) do
    max_length = Keyword.get(opts, :length, @default_length)

    if String.length(text) <= max_length do
      text
    else
      text
      |> String.slice(0, max_length)
      |> String.split()
      |> Enum.drop(-1)
      |> Enum.join(" ")
      |> Kernel.<>("...")
    end
  end

  defp truncate(_, _), do: ""
end
