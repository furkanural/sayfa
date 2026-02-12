defmodule Mix.Tasks.Sayfa.New do
  @moduledoc """
  Generates a new Sayfa site project.

  ## Usage

      mix sayfa.new my_blog [--title "My Blog"] [--lang en,tr]

  ## Options

  - `--title` — site title (default: derived from project name)
  - `--lang` — comma-separated language codes (default: `en`)

  ## Examples

      mix sayfa.new my_blog
      mix sayfa.new my_blog --title "My Blog" --lang en,tr

  """

  use Mix.Task

  @shortdoc "Create a new Sayfa site project"

  @switches [
    title: :string,
    lang: :string
  ]

  @templates_dir "priv/templates/new_site"

  @impl Mix.Task
  def run(args) do
    {opts, argv, _} = OptionParser.parse(args, switches: @switches)

    case argv do
      [path | _] ->
        generate(path, opts)

      [] ->
        Mix.shell().error("Expected a project path. Usage: mix sayfa.new my_site")
        exit({:shutdown, 1})
    end
  end

  defp generate(path, opts) do
    project_name = Path.basename(path)
    module_name = Macro.camelize(project_name)
    title = Keyword.get(opts, :title, humanize(project_name))

    languages =
      opts
      |> Keyword.get(:lang, "en")
      |> String.split(",")
      |> Enum.map(&String.trim/1)

    assigns = [
      project_name: project_name,
      module_name: module_name,
      title: title,
      languages: languages,
      default_lang: hd(languages),
      sayfa_version: "0.1"
    ]

    if File.exists?(path) do
      Mix.shell().error("Directory #{path} already exists!")
      exit({:shutdown, 1})
    end

    Mix.shell().info(IO.ANSI.green() <> "Creating new Sayfa site: #{title}" <> IO.ANSI.reset())

    Mix.shell().info("")

    # Create directory structure
    dirs = [
      path,
      Path.join(path, "config"),
      Path.join(path, "content/posts"),
      Path.join(path, "content/pages"),
      Path.join(path, ".github/workflows")
    ]

    Enum.each(dirs, &File.mkdir_p!/1)

    # Create language subdirectories for non-default languages
    languages
    |> tl()
    |> Enum.each(fn lang ->
      File.mkdir_p!(Path.join([path, "content", lang, "posts"]))
    end)

    # Generate files from templates
    templates_dir = templates_path()

    write_template(templates_dir, "mix.exs.eex", Path.join(path, "mix.exs"), assigns)
    write_template(templates_dir, "config.exs.eex", Path.join(path, "config/config.exs"), assigns)

    write_template(
      templates_dir,
      "welcome.md.eex",
      Path.join(path, "content/posts/welcome.md"),
      assigns
    )

    write_template(
      templates_dir,
      "about.md.eex",
      Path.join(path, "content/pages/about.md"),
      assigns
    )

    write_template(
      templates_dir,
      "index.md.eex",
      Path.join(path, "content/pages/index.md"),
      assigns
    )

    write_template(
      templates_dir,
      "readme.md.eex",
      Path.join(path, "README.md"),
      assigns
    )

    # Copy static files (no EEx processing)
    copy_static(templates_dir, "formatter.exs", Path.join(path, ".formatter.exs"))
    copy_static(templates_dir, "gitignore", Path.join(path, ".gitignore"))
    copy_static(templates_dir, "Dockerfile", Path.join(path, "Dockerfile"))

    copy_static(
      templates_dir,
      "github/workflows/deploy.yml",
      Path.join(path, ".github/workflows/deploy.yml")
    )

    # Initialize git repository
    git_init(path)

    # Print project structure and next steps
    print_success(path, project_name)
  end

  defp write_template(templates_dir, template_name, dest_path, assigns) do
    template_path = Path.join(templates_dir, template_name)
    content = EEx.eval_file(template_path, assigns: Map.new(assigns))
    File.write!(dest_path, content)
    print_created(dest_path)
  end

  defp copy_static(templates_dir, source_name, dest_path) do
    source_path = Path.join(templates_dir, source_name)
    File.cp!(source_path, dest_path)
    print_created(dest_path)
  end

  defp print_created(path) do
    Mix.shell().info("  #{IO.ANSI.green()}create#{IO.ANSI.reset()} #{path}")
  end

  defp git_init(path) do
    case System.find_executable("git") do
      nil ->
        Mix.shell().info(
          "  #{IO.ANSI.yellow()}skip#{IO.ANSI.reset()} git init (git not found on PATH)"
        )

      _git ->
        case System.cmd("git", ["init"], cd: path, stderr_to_stdout: true) do
          {_, 0} ->
            Mix.shell().info("  #{IO.ANSI.green()}init#{IO.ANSI.reset()} git repository")

          {output, _} ->
            Mix.shell().info(
              "  #{IO.ANSI.yellow()}skip#{IO.ANSI.reset()} git init (#{String.trim(output)})"
            )
        end
    end
  end

  defp print_success(path, _project_name) do
    Mix.shell().info("")

    Mix.shell().info(IO.ANSI.green() <> "Your Sayfa site has been created!" <> IO.ANSI.reset())

    Mix.shell().info("")
    Mix.shell().info("Next steps:")
    Mix.shell().info("")
    Mix.shell().info("    cd #{path}")
    Mix.shell().info("    mix deps.get")
    Mix.shell().info("    mix sayfa.serve        # Start dev server")
    Mix.shell().info("    mix sayfa.build        # Build the site")
    Mix.shell().info("")
    Mix.shell().info("Customize your site:")
    Mix.shell().info("")
    Mix.shell().info("    Edit content/pages/index.md to update your home page")
    Mix.shell().info("    Edit config/config.exs to configure your site")
    Mix.shell().info("    Run mix sayfa.gen.layout home to customize a layout")
    Mix.shell().info("")
  end

  defp templates_path do
    case :code.priv_dir(:sayfa) do
      {:error, :bad_name} ->
        Path.join(File.cwd!(), @templates_dir)

      dir ->
        Path.join(List.to_string(dir), "templates/new_site")
    end
  end

  defp humanize(name) do
    name
    |> String.replace(~r/[_-]/, " ")
    |> String.split()
    |> Enum.map_join(" ", &String.capitalize/1)
  end
end
