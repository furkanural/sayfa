defmodule Sayfa.I18n do
  @moduledoc """
  Multilingual support using subdirectory-based language detection.

  Content files placed in a language subdirectory (e.g., `content/tr/posts/merhaba.md`)
  are detected as that language and output with a language prefix in the URL
  (e.g., `/tr/posts/merhaba/`).

  The default language has no URL prefix. Non-default languages get `/<lang>/` prefix.

  ## Configuration

      config :sayfa, :site,
        default_lang: :en,
        languages: [
          en: [name: "English"],
          tr: [name: "Türkçe"]
        ]

  ## Translation Lookup

  Translations are resolved in this order:

  1. Language-specific translations from user config (`languages: [tr: [translations: %{...}]]`)
  2. YAML translation file for the requested language (`priv/translations/{lang}.yml`)
  3. YAML translation file for the default language (`priv/translations/{default_lang}.yml`)
  4. The key itself as fallback

  Sayfa ships pre-built YAML translations for 14 languages: en, tr, de, es, fr, it,
  pt, ja, ko, zh, ar, ru, nl, pl.

  ## Examples

      iex> config = %{default_lang: :en, languages: [en: [name: "English"], tr: [name: "Türkçe"]]}
      iex> Sayfa.I18n.detect_language("tr/posts/merhaba.md", config)
      {:tr, "posts/merhaba.md"}

      iex> config = %{default_lang: :en, languages: [en: [name: "English"]]}
      iex> Sayfa.I18n.detect_language("posts/hello.md", config)
      {:en, "posts/hello.md"}

  """

  @doc """
  Detects the language from a relative file path.

  If the first path segment matches a configured language code (other than default),
  returns `{lang, remaining_path}`. Otherwise returns `{default_lang, path}`.

  ## Examples

      iex> config = %{default_lang: :en, languages: [en: [name: "English"], tr: [name: "Türkçe"]]}
      iex> Sayfa.I18n.detect_language("tr/posts/merhaba.md", config)
      {:tr, "posts/merhaba.md"}

      iex> config = %{default_lang: :en, languages: [en: [name: "English"], tr: [name: "Türkçe"]]}
      iex> Sayfa.I18n.detect_language("posts/hello.md", config)
      {:en, "posts/hello.md"}

      iex> config = %{default_lang: :en, languages: [en: [name: "English"]]}
      iex> Sayfa.I18n.detect_language("about.md", config)
      {:en, "about.md"}

  """
  @spec detect_language(String.t(), map()) :: {atom(), String.t()}
  def detect_language(relative_path, config) do
    parts = Path.split(relative_path)
    lang_codes = configured_language_codes(config)
    default = config.default_lang

    case parts do
      [first | rest] when rest != [] ->
        lang = String.to_atom(first)

        if lang in lang_codes and lang != default do
          {lang, Path.join(rest)}
        else
          {default, relative_path}
        end

      _ ->
        {default, relative_path}
    end
  end

  @doc """
  Returns the URL prefix for a language.

  Default language returns `""` (no prefix). Non-default languages return
  the language code as a string (e.g., `"tr"`).

  ## Examples

      iex> config = %{default_lang: :en}
      iex> Sayfa.I18n.language_prefix(:en, config)
      ""

      iex> config = %{default_lang: :en}
      iex> Sayfa.I18n.language_prefix(:tr, config)
      "tr"

  """
  @spec language_prefix(atom(), map()) :: String.t()
  def language_prefix(lang, config) do
    if lang == config.default_lang do
      ""
    else
      Atom.to_string(lang)
    end
  end

  @doc """
  Returns the list of configured language codes.

  ## Examples

      iex> config = %{languages: [en: [name: "English"], tr: [name: "Türkçe"]]}
      iex> Sayfa.I18n.configured_language_codes(config)
      [:en, :tr]

  """
  @spec configured_language_codes(map()) :: [atom()]
  def configured_language_codes(config) do
    config
    |> Map.get(:languages, en: [name: "English"])
    |> Keyword.keys()
  end

  @doc """
  Translates a UI string key for a given language.

  Supports optional bindings for interpolation and pluralization.
  When the translation value is a map with `"one"` and `"other"` keys,
  the `:count` binding selects the plural form. All bindings are interpolated
  as `%{key}` in the resulting string.

  Lookup chain:
  1. Language-specific translations from config
  2. YAML translation file for the requested language
  3. YAML translation file for the default language
  4. The key itself as fallback

  ## Examples

      iex> config = %{default_lang: :en, languages: [en: [name: "English"], tr: [name: "Türkçe", translations: %{"next" => "Sonraki"}]]}
      iex> Sayfa.I18n.t("next", :tr, config)
      "Sonraki"

      iex> config = %{default_lang: :en, languages: [en: [name: "English"]]}
      iex> Sayfa.I18n.t("next", :en, config)
      "Next"

      iex> config = %{default_lang: :en, languages: [en: [name: "English"]]}
      iex> Sayfa.I18n.t("unknown_key", :en, config)
      "unknown_key"

  """
  @spec t(String.t(), atom(), map(), keyword()) :: String.t()
  def t(key, lang, config, bindings \\ []) do
    value = resolve_translation(key, lang, config)

    string =
      case value do
        %{"other" => other} = map ->
          count = Keyword.get(bindings, :count)

          if count do
            select_plural_form(map, count)
          else
            other
          end

        s when is_binary(s) ->
          s

        _ ->
          to_string(value)
      end

    interpolate(string, bindings)
  end

  defp resolve_translation(key, lang, config) do
    languages = Map.get(config, :languages, [])

    lang_translations =
      languages
      |> Keyword.get(lang, [])
      |> Keyword.get(:translations, %{})

    default_lang = Map.get(config, :default_lang, :en)

    default_translations =
      languages
      |> Keyword.get(default_lang, [])
      |> Keyword.get(:translations, %{})

    yaml_translations = load_translations(lang)
    default_yaml = load_translations(default_lang)

    Map.get(lang_translations, key) ||
      Map.get(default_translations, key) ||
      Map.get(yaml_translations, key) ||
      Map.get(default_yaml, key) ||
      key
  end

  defp select_plural_form(forms, 1), do: Map.get(forms, "one", Map.get(forms, "other", ""))
  defp select_plural_form(forms, _count), do: Map.get(forms, "other", "")

  defp interpolate(string, bindings) do
    Enum.reduce(bindings, string, fn {key, val}, acc ->
      String.replace(acc, "%{#{key}}", to_string(val))
    end)
  end

  @doc """
  Returns a translation closure for a given language and config.

  The returned function takes a key and returns the translated string.

  ## Examples

      iex> config = %{default_lang: :en, languages: [en: [name: "English"]]}
      iex> t = Sayfa.I18n.translate_function(:en, config)
      iex> t.("next")
      "Next"

  """
  @spec translate_function(atom(), map()) :: (String.t() -> String.t())
  def translate_function(lang, config) do
    fn key -> t(key, lang, config) end
  end

  @doc """
  Returns a default translation function that uses English YAML translations.

  Used as a fallback when no language-specific translation function is available.

  ## Examples

      iex> t = Sayfa.I18n.default_translate_function()
      iex> t.("next")
      "Next"

  """
  @spec default_translate_function() :: (String.t() -> String.t())
  def default_translate_function do
    translations = load_translations(:en)
    fn key -> Map.get(translations, key, key) end
  end

  @doc """
  Resolves per-language site configuration overrides.

  Extracts language-specific config from the `languages` keyword list,
  excluding `:name` and `:translations`, and merges onto the base config.

  ## Examples

      iex> config = %{title: "My Blog", default_lang: :en, languages: [en: [name: "English"], tr: [name: "Türkçe", title: "Blogum"]]}
      iex> resolved = Sayfa.I18n.resolve_site_config(config, :tr, config)
      iex> resolved.title
      "Blogum"

      iex> config = %{title: "My Blog", default_lang: :en, languages: [en: [name: "English"]]}
      iex> resolved = Sayfa.I18n.resolve_site_config(config, :en, config)
      iex> resolved.title
      "My Blog"

  """
  @spec resolve_site_config(map(), atom(), map()) :: map()
  def resolve_site_config(base_config, lang, config) do
    languages = Map.get(config, :languages, [])

    overrides =
      languages
      |> Keyword.get(lang, [])
      |> Keyword.drop([:name, :translations])
      |> Map.new()

    Map.merge(base_config, overrides)
  end

  @rtl_languages [:ar, :he, :fa, :ur]

  @doc """
  Returns whether the given language code is a right-to-left language.

  ## Examples

      iex> Sayfa.I18n.rtl_language?(:ar)
      true

      iex> Sayfa.I18n.rtl_language?(:en)
      false

  """
  @spec rtl_language?(atom()) :: boolean()
  def rtl_language?(lang), do: lang in @rtl_languages

  @doc """
  Returns the text direction for a language code.

  Returns `"rtl"` for right-to-left languages (Arabic, Hebrew, Farsi, Urdu)
  and `"ltr"` for all others.

  ## Examples

      iex> Sayfa.I18n.text_direction(:ar)
      "rtl"

      iex> Sayfa.I18n.text_direction(:en)
      "ltr"

  """
  @spec text_direction(atom()) :: String.t()
  def text_direction(lang) do
    if rtl_language?(lang), do: "rtl", else: "ltr"
  end

  @doc """
  Loads translations for a language from YAML files.

  Results are cached in `:persistent_term` for fast subsequent lookups.
  Returns an empty map if no YAML file exists for the language.

  ## Examples

      iex> translations = Sayfa.I18n.load_translations(:en)
      iex> Map.get(translations, "next")
      "Next"

  """
  @spec load_translations(atom()) :: map()
  def load_translations(lang) do
    key = {__MODULE__, :translations, lang}

    case :persistent_term.get(key, :not_loaded) do
      :not_loaded ->
        translations = do_load_translations(lang)
        :persistent_term.put(key, translations)
        translations

      cached ->
        cached
    end
  end

  @doc """
  Clears the translation cache.

  Useful for testing or when translation files have been updated.
  """
  @spec clear_cache() :: :ok
  def clear_cache do
    :persistent_term.get()
    |> Enum.each(fn
      {{__MODULE__, :translations, lang}, _value} ->
        :persistent_term.erase({__MODULE__, :translations, lang})

      _ ->
        :ok
    end)

    :ok
  end

  defp do_load_translations(lang) do
    path = translations_path(lang)

    with true <- File.exists?(path),
         {:ok, translations} when is_map(translations) <- YamlElixir.read_from_file(path) do
      Map.new(translations, fn {k, v} -> {to_string(k), normalize_value(v)} end)
    else
      _ -> %{}
    end
  end

  defp normalize_value(v) when is_map(v),
    do: Map.new(v, fn {k, val} -> {to_string(k), normalize_value(val)} end)

  defp normalize_value(v), do: to_string(v)

  defp translations_path(lang) do
    :sayfa
    |> :code.priv_dir()
    |> Path.join("translations/#{lang}.yml")
  end
end
