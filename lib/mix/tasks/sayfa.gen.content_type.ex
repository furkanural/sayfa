defmodule Mix.Tasks.Sayfa.Gen.ContentType do
  @moduledoc """
  Generates a custom content type module scaffold.

  ## Usage

      mix sayfa.gen.content_type ModuleName

  ## Examples

      mix sayfa.gen.content_type Recipe
      mix sayfa.gen.content_type MyApp.ContentTypes.Tutorial

  The last segment of the module name is used to derive the type name and file name.
  For example, `Recipe` produces `lib/content_types/recipe.ex` with type name `:recipe`.

  ## After generation

  Register your content type and create its content directory:

      # In config/config.exs:
      config :sayfa, :content_types, [MyApp.ContentTypes.Recipe | Sayfa.ContentType.default_types()]

      # Create the content directory:
      mkdir -p content/recipes
  """

  use Mix.Task

  @shortdoc "Scaffold a custom content type module"

  @impl Mix.Task
  def run([module_name | _]) do
    last_segment = module_name |> String.split(".") |> List.last()
    type_name = to_snake_case(last_segment)
    file_path = Path.join(["lib", "content_types", "#{type_name}.ex"])

    if File.exists?(file_path) do
      Mix.shell().error("File already exists: #{file_path}")
      exit({:shutdown, 1})
    end

    template_path =
      Path.join([
        to_string(:code.priv_dir(:sayfa)),
        "templates",
        "gen_content_type",
        "content_type.ex.eex"
      ])

    content =
      EEx.eval_file(template_path,
        assigns: [module_name: module_name, type_name: type_name]
      )

    File.mkdir_p!(Path.dirname(file_path))
    File.write!(file_path, content)

    Mix.shell().info("#{IO.ANSI.green()}Created#{IO.ANSI.reset()} #{file_path}")
    Mix.shell().info("")
    Mix.shell().info("Register your content type in config/config.exs:")
    Mix.shell().info("")

    Mix.shell().info(
      "    config :sayfa, :content_types, [#{module_name} | Sayfa.ContentType.default_types()]"
    )

    Mix.shell().info("")
    Mix.shell().info("Create the content directory:")
    Mix.shell().info("")
    Mix.shell().info("    mkdir -p content/#{type_name}s")
  end

  def run([]) do
    Mix.shell().error("Usage: mix sayfa.gen.content_type ModuleName")
    exit({:shutdown, 1})
  end

  defp to_snake_case(name) do
    name
    |> String.replace(~r/([A-Z]+)([A-Z][a-z])/, "\\1_\\2")
    |> String.replace(~r/([a-z\d])([A-Z])/, "\\1_\\2")
    |> String.downcase()
  end
end
