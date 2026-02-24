defmodule Mix.Tasks.Sayfa.Gen.Lang do
  @moduledoc """
  Adds a new language to an existing Sayfa site.

  ## Usage

      mix sayfa.gen.lang LANG_CODE

  ## Examples

      mix sayfa.gen.lang tr
      mix sayfa.gen.lang de

  Creates `content/{lang}/pages/` and `content/{lang}/posts/` directories,
  generates starter content files, and updates `config/config.exs` with the
  new language entry.
  """

  use Mix.Task

  @shortdoc "Add a new language to an existing Sayfa site"

  @templates_dir "priv/templates/new_site"

  @language_names %{
    "tr" => "Türkçe",
    "de" => "Deutsch",
    "es" => "Español",
    "fr" => "Français",
    "it" => "Italiano",
    "pt" => "Português",
    "ja" => "日本語",
    "ko" => "한국어",
    "zh" => "中文",
    "ar" => "العربية",
    "ru" => "Русский",
    "nl" => "Nederlands",
    "pl" => "Polski",
    "en" => "English"
  }

  @impl Mix.Task
  def run(args) do
    case args do
      [lang | _] ->
        add_language(lang)

      [] ->
        Mix.shell().error("Expected a language code. Usage: mix sayfa.gen.lang LANG_CODE")
        exit({:shutdown, 1})
    end
  end

  defp add_language(lang) do
    config_path = "config/config.exs"

    unless File.exists?(config_path) do
      Mix.shell().error("No config/config.exs found. Are you inside a Sayfa project?")
      exit({:shutdown, 1})
    end

    {title, default_lang, existing_languages} = read_config(config_path)
    already_present = lang in existing_languages

    if already_present do
      Mix.shell().info(
        IO.ANSI.yellow() <>
          "warning" <>
          IO.ANSI.reset() <>
          " Language \"#{lang}\" is already in the languages list."
      )
    end

    templates_dir = templates_path()
    lang_path = Path.join("content", lang)

    File.mkdir_p!(Path.join(lang_path, "pages"))
    File.mkdir_p!(Path.join(lang_path, "posts"))

    assigns = [title: title, lang: lang, default_lang: default_lang]

    generate_file(
      templates_dir,
      lang_template_name(templates_dir, lang, "index.md.eex"),
      Path.join([lang_path, "pages", "index.md"]),
      assigns
    )

    generate_file(
      templates_dir,
      lang_template_name(templates_dir, lang, "about.md.eex"),
      Path.join([lang_path, "pages", "about.md"]),
      assigns
    )

    generate_file(
      templates_dir,
      lang_template_name(templates_dir, lang, "building-with-sayfa.md.eex"),
      Path.join([lang_path, "posts", "building-with-sayfa.md"]),
      assigns
    )

    unless already_present do
      name = Map.get(@language_names, lang, String.capitalize(lang))
      update_config_languages(config_path, lang, name)
    end

    name = Map.get(@language_names, lang, String.capitalize(lang))
    Mix.shell().info("")
    Mix.shell().info(IO.ANSI.green() <> "Language #{lang} (#{name}) added!" <> IO.ANSI.reset())
  end

  defp read_config(config_path) do
    config = Config.Reader.read!(config_path)
    site_config = get_in(config, [:sayfa, :site]) || []
    title = Keyword.get(site_config, :title, "My Site")
    default_lang = site_config |> Keyword.get(:default_lang, :en) |> to_string()

    existing_languages =
      site_config
      |> Keyword.get(:languages, [])
      |> Keyword.keys()
      |> Enum.map(&to_string/1)

    {title, default_lang, existing_languages}
  end

  defp update_config_languages(config_path, lang, name) do
    content = File.read!(config_path)
    pattern = ~r/(languages:\s*\[)((?:[^\[\]]*(?:\[[^\[\]]*\])?)*)\]/
    new_entry = "#{lang}: [name: \"#{name}\"]"

    updated =
      Regex.replace(pattern, content, fn _, prefix, existing ->
        if String.trim(existing) == "",
          do: "#{prefix}#{new_entry}]",
          else: "#{prefix}#{String.trim(existing)}, #{new_entry}]"
      end)

    if updated == content do
      Mix.shell().info(
        IO.ANSI.yellow() <>
          "warning" <>
          IO.ANSI.reset() <>
          " Could not automatically update config. Add the following manually:\n\n" <>
          "    #{new_entry}"
      )
    else
      File.write!(config_path, updated)
      Mix.shell().info("  #{IO.ANSI.green()}update#{IO.ANSI.reset()} #{config_path}")
    end
  end

  defp generate_file(templates_dir, template_name, dest_path, assigns) do
    if File.exists?(dest_path) do
      Mix.shell().info(
        "  #{IO.ANSI.yellow()}skip#{IO.ANSI.reset()}   #{dest_path} (already exists)"
      )
    else
      template_path = Path.join(templates_dir, template_name)
      content = EEx.eval_file(template_path, assigns: Map.new(assigns))
      File.write!(dest_path, content)
      Mix.shell().info("  #{IO.ANSI.green()}create#{IO.ANSI.reset()} #{dest_path}")
    end
  end

  defp lang_template_name(templates_dir, lang, name) do
    specific = "lang/#{lang}/#{name}"

    if File.exists?(Path.join(templates_dir, specific)),
      do: specific,
      else: "lang/#{name}"
  end

  defp templates_path do
    case :code.priv_dir(:sayfa) do
      {:error, :bad_name} ->
        Path.join(File.cwd!(), @templates_dir)

      dir ->
        Path.join(List.to_string(dir), "templates/new_site")
    end
  end
end
