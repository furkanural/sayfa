defmodule Sayfa.DateFormat do
  @moduledoc """
  Locale-aware date formatting.

  Provides centralized date formatting that replaces `%B` and `%b` format
  directives with translated month names from YAML translation files.

  The format string is resolved in this order:
  1. Per-language `date_format` override in site config
  2. `date_format` key from YAML translations for the language
  3. Default `"%b %-d, %Y"` (English style)

  ## Examples

      iex> Sayfa.DateFormat.format(~D[2024-02-15], :en)
      "Feb 15, 2024"

  """

  @default_format "%b %-d, %Y"

  @doc """
  Formats a date using locale-aware month names.

  ## Examples

      iex> Sayfa.DateFormat.format(~D[2024-01-15], :en)
      "Jan 15, 2024"

  """
  @spec format(Date.t(), atom(), map()) :: String.t()
  def format(%Date{} = date, lang, config \\ %{}) do
    fmt = resolve_format(lang, config)
    translations = Sayfa.I18n.load_translations(lang)

    fmt
    |> replace_month_names(date, translations)
    |> then(&Calendar.strftime(date, &1))
  end

  defp resolve_format(lang, config) do
    lang_format = get_lang_config_format(lang, config)

    if lang_format do
      lang_format
    else
      translations = Sayfa.I18n.load_translations(lang)

      case Map.get(translations, "date_format") do
        nil -> @default_format
        fmt -> fmt
      end
    end
  end

  defp get_lang_config_format(lang, config) do
    languages = Map.get(config, :languages, [])

    languages
    |> Keyword.get(lang, [])
    |> Keyword.get(:date_format)
  end

  defp replace_month_names(fmt, date, translations) do
    month = date.month

    fmt
    |> maybe_replace_full_month(month, translations)
    |> maybe_replace_abbr_month(month, translations)
  end

  defp maybe_replace_full_month(fmt, month, translations) do
    case Map.get(translations, "month_#{month}") do
      nil -> fmt
      name -> String.replace(fmt, "%B", name)
    end
  end

  defp maybe_replace_abbr_month(fmt, month, translations) do
    case Map.get(translations, "month_#{month}_abbr") do
      nil -> fmt
      name -> String.replace(fmt, "%b", name)
    end
  end
end
