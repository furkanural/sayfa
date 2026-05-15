defmodule Sayfa.Blocks.Helpers do
  @moduledoc """
  Shared helper functions for blocks.

  Extracts common patterns that would otherwise be duplicated across
  multiple block modules (language filtering, URL prefix generation, etc.).
  """

  alias Sayfa.I18n

  @doc """
  Filters contents to only those matching the given language.

  Returns the full list when `lang` is `nil`.

  ## Examples

      iex> contents = [%Sayfa.Content{title: "A", body: "", lang: :en}, %Sayfa.Content{title: "B", body: "", lang: :tr}]
      iex> Sayfa.Blocks.Helpers.filter_by_lang(contents, :en) |> length()
      1

      iex> Sayfa.Blocks.Helpers.filter_by_lang(contents, nil) |> length()
      2

  """
  @spec filter_by_lang([Sayfa.Content.t()], atom() | nil) :: [Sayfa.Content.t()]
  def filter_by_lang(contents, nil), do: contents
  def filter_by_lang(contents, lang), do: Enum.filter(contents, &(&1.lang == lang))

  @doc """
  Returns the language prefix path segment for a given language.

  Returns `""` when the language matches the site default.

  ## Examples

      iex> Sayfa.Blocks.Helpers.lang_prefix_path(nil, %{})
      ""

  """
  @spec lang_prefix_path(atom() | nil, map()) :: String.t()
  def lang_prefix_path(nil, _site), do: ""

  def lang_prefix_path(lang, site) do
    case I18n.language_prefix(lang, site) do
      "" -> ""
      prefix -> "/#{prefix}"
    end
  end
end
