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

  Returns `""` when `date` is `nil`.

  Accepts `%Date{}`, `%DateTime{}`, `%NaiveDateTime{}`, or an ISO 8601 string.
  `DateTime` and `NaiveDateTime` values are converted to their date component.
  String values are parsed via `Date.from_iso8601/1`; if unparseable, the
  original string is returned as-is.

  ## Examples

      iex> Sayfa.DateFormat.format(~D[2024-01-15], :en)
      "Jan 15, 2024"

      iex> Sayfa.DateFormat.format(nil, :en)
      ""

      iex> Sayfa.DateFormat.format(~U[2024-01-15 10:00:00Z], :en)
      "Jan 15, 2024"

      iex> Sayfa.DateFormat.format(~N[2024-01-15 10:00:00], :en)
      "Jan 15, 2024"

      iex> Sayfa.DateFormat.format("2024-01-15", :en)
      "Jan 15, 2024"

  """
  @spec format(Date.t() | DateTime.t() | NaiveDateTime.t() | String.t() | nil, atom(), map()) ::
          String.t()
  def format(date, lang, config \\ %{})
  def format(nil, _lang, _config), do: ""
  def format(%DateTime{} = dt, lang, config), do: format(DateTime.to_date(dt), lang, config)

  def format(%NaiveDateTime{} = ndt, lang, config),
    do: format(NaiveDateTime.to_date(ndt), lang, config)

  def format(date, lang, config) when is_binary(date) do
    case Date.from_iso8601(date) do
      {:ok, parsed} -> format(parsed, lang, config)
      {:error, _} -> date
    end
  end

  def format(%Date{} = date, lang, config) do
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
