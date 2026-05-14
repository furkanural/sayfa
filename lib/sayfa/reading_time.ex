defmodule Sayfa.ReadingTime do
  @moduledoc """
  Calculates estimated reading time from HTML content.

  Uses an average reading speed of 200 words per minute.

  ## Examples

      iex> Sayfa.ReadingTime.calculate("<p>Hello world</p>")
      1

  """

  @default_words_per_minute 200

  @doc """
  Calculates reading time in minutes from an HTML string.

  Uses `words_per_minute` from site config (default: 200).
  Returns at least 1 minute even for very short content.

  ## Examples

      iex> Sayfa.ReadingTime.calculate("<p>Hello world</p>")
      1

      iex> Sayfa.ReadingTime.calculate("")
      1

      iex> long_text = String.duplicate("word ", 600)
      iex> Sayfa.ReadingTime.calculate("<p>" <> long_text <> "</p>")
      3

  """
  @spec calculate(String.t()) :: pos_integer()
  def calculate(html) when is_binary(html) do
    wpm = Sayfa.Config.get(:words_per_minute, @default_words_per_minute)

    html
    |> strip_tags()
    |> String.split(~r/\s+/, trim: true)
    |> length()
    |> then(&max(1, div(&1, wpm)))
  end

  defp strip_tags(html) do
    Regex.replace(~r/<[^>]*>/, html, " ")
  end
end
