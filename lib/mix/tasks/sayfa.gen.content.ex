defmodule Mix.Tasks.Sayfa.Gen.Content do
  @moduledoc """
  Generates a new content file with front matter scaffolding.

  ## Usage

      mix sayfa.gen.content TYPE TITLE [options]
      mix sayfa.gen.content --list

  ## Examples

      mix sayfa.gen.content post "My First Post"
      mix sayfa.gen.content note "Quick Tip"
      mix sayfa.gen.content project "My Project" --tags=elixir,oss --draft
      mix sayfa.gen.content talk "Intro to Elixir" --date=2026-03-15
      mix sayfa.gen.content post "Hello World" --lang=en,tr
      mix sayfa.gen.content --list

  ## Options

    * `--list` - List available content types
    * `--date` - Override date (default: today), format YYYY-MM-DD
    * `--tags` - Comma-separated tags
    * `--categories` - Comma-separated categories
    * `--draft` - Mark as draft
    * `--lang` - Language code or comma-separated codes (e.g., `en` or `en,tr`)
    * `--slug` - Custom slug (default: slugified from title)

  When multiple languages are provided, one file is generated per language
  with `translations` front matter pre-wired to link them together.

  Files are created under `content/{type_directory}/` with appropriate
  front matter based on the content type's required fields.
  """

  use Mix.Task

  @shortdoc "Generate a new content file with front matter"

  @switches [
    list: :boolean,
    date: :string,
    tags: :string,
    categories: :string,
    draft: :boolean,
    lang: :string,
    slug: :string
  ]

  @impl Mix.Task
  def run(args) do
    {opts, argv, _} = OptionParser.parse(args, switches: @switches)

    cond do
      Keyword.get(opts, :list, false) ->
        list_content_types()

      length(argv) < 2 ->
        Mix.shell().error("Expected TYPE and TITLE. Usage: mix sayfa.gen.content TYPE \"Title\"")

        Mix.shell().info("")
        list_content_types()
        exit({:shutdown, 1})

      true ->
        [type_name | title_parts] = argv
        title = Enum.join(title_parts, " ")
        generate_content(type_name, title, opts)
    end
  end

  defp generate_content(type_name, title, opts) do
    type_atom = String.to_atom(type_name)

    case Sayfa.ContentType.find_by_name(type_atom) do
      nil ->
        Mix.shell().error("Unknown content type \"#{type_name}\".")
        Mix.shell().info("")
        list_content_types()
        exit({:shutdown, 1})

      type_mod ->
        do_generate(type_mod, title, opts)
    end
  end

  defp do_generate(type_mod, title, opts) do
    slug = Keyword.get(opts, :slug) || Slug.slugify(title)
    date = parse_date_option(Keyword.get(opts, :date))
    tags = parse_list_option(Keyword.get(opts, :tags))
    categories = parse_list_option(Keyword.get(opts, :categories))
    draft = Keyword.get(opts, :draft, false)
    langs = opts |> Keyword.get(:lang) |> parse_lang_option()
    required = type_mod.required_fields()
    has_date = :date in required

    default_lang = List.first(langs)

    Enum.each(langs, fn lang ->
      translations = build_translations(lang, langs, slug)

      front_matter =
        build_front_matter(title, date, tags, categories, draft, has_date, lang, translations)

      filename = build_filename(slug, date, has_date)
      path_lang = if lang == default_lang, do: nil, else: lang
      path = build_path(type_mod.directory(), filename, path_lang)

      if File.exists?(path) do
        Mix.shell().info("#{IO.ANSI.yellow()}Skipping#{IO.ANSI.reset()} #{path} (already exists)")
      else
        content = render_content(front_matter, title)

        path |> Path.dirname() |> File.mkdir_p!()
        File.write!(path, content)

        Mix.shell().info("#{IO.ANSI.green()}Created#{IO.ANSI.reset()} #{path}")
      end
    end)
  end

  defp build_front_matter(title, date, tags, categories, draft, has_date, lang, translations) do
    lines = [~s(title: "#{title}")]

    lines =
      if has_date do
        lines ++ ["date: #{Date.to_iso8601(date)}"]
      else
        lines
      end

    lines = lines ++ [~s(description: "")]

    lines =
      if categories != [],
        do: lines ++ ["categories: [#{Enum.join(categories, ", ")}]"],
        else: lines ++ ["categories: []"]

    lines =
      if tags != [],
        do: lines ++ ["tags: [#{Enum.join(tags, ", ")}]"],
        else: lines ++ ["tags: []"]

    lines = if draft, do: lines ++ ["draft: true"], else: lines ++ ["draft: false"]

    lines =
      case lang do
        nil -> lines
        l -> lines ++ ["lang: #{l}"]
      end

    lines =
      if translations != %{} do
        translation_lines =
          translations
          |> Enum.sort()
          |> Enum.map(fn {k, v} -> "  #{k}: #{v}" end)

        lines ++ ["translations:"] ++ translation_lines
      else
        lines
      end

    Enum.join(lines, "\n")
  end

  defp build_filename(slug, date, true = _has_date) do
    "#{Date.to_iso8601(date)}-#{slug}.md"
  end

  defp build_filename(slug, _date, false = _has_date) do
    "#{slug}.md"
  end

  defp build_path(directory, filename, nil) do
    Path.join(["content", directory, filename])
  end

  defp build_path(directory, filename, lang) do
    Path.join(["content", lang, directory, filename])
  end

  defp render_content(front_matter, title) do
    """
    ---
    #{front_matter}
    ---

    # #{title}

    Write your content here.
    """
  end

  defp parse_lang_option(nil), do: [nil]
  defp parse_lang_option(str), do: str |> String.split(",") |> Enum.map(&String.trim/1)

  defp build_translations(_current_lang, langs, _slug) when length(langs) <= 1, do: %{}

  defp build_translations(current_lang, langs, slug) do
    langs
    |> Enum.reject(&(&1 == current_lang))
    |> Map.new(fn lang -> {lang, slug} end)
  end

  defp parse_date_option(nil), do: Date.utc_today()

  defp parse_date_option(date_str) do
    case Date.from_iso8601(date_str) do
      {:ok, date} ->
        date

      {:error, _} ->
        Mix.shell().error("Invalid date format \"#{date_str}\". Expected YYYY-MM-DD.")
        exit({:shutdown, 1})
    end
  end

  defp parse_list_option(nil), do: []
  defp parse_list_option(str), do: str |> String.split(",") |> Enum.map(&String.trim/1)

  defp list_content_types do
    types = Sayfa.ContentType.all()

    Mix.shell().info("Available content types:")
    Mix.shell().info("")

    Enum.each(types, fn mod ->
      name = mod.name()
      dir = mod.directory()
      Mix.shell().info("  #{name}\t(content/#{dir}/)")
    end)
  end
end
