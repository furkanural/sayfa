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
    |> Map.get(:languages, [en: [name: "English"]])
    |> Keyword.keys()
  end
end
