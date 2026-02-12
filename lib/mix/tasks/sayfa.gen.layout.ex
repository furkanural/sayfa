defmodule Mix.Tasks.Sayfa.Gen.Layout do
  @moduledoc """
  Copies a default layout to your project for customization.

  ## Usage

      mix sayfa.gen.layout LAYOUT_NAME
      mix sayfa.gen.layout --list

  ## Examples

      mix sayfa.gen.layout post     # Copy post layout for customization
      mix sayfa.gen.layout home     # Copy home layout for customization
      mix sayfa.gen.layout --list   # Show available layouts

  Layouts are copied to `themes/custom/layouts/` in your project.
  Set `theme: "custom"` in `config/config.exs` to use them.
  """

  use Mix.Task

  @shortdoc "Copy a default layout for customization"

  @impl Mix.Task
  def run(args) do
    {opts, argv, _} = OptionParser.parse(args, switches: [list: :boolean])

    cond do
      Keyword.get(opts, :list, false) ->
        list_layouts()

      argv == [] ->
        Mix.shell().error("Expected a layout name. Usage: mix sayfa.gen.layout LAYOUT_NAME")
        Mix.shell().info("")
        list_layouts()
        exit({:shutdown, 1})

      true ->
        copy_layout(hd(argv))
    end
  end

  defp copy_layout(name) do
    source = Sayfa.Config.default_theme_path("layouts/#{name}.html.eex")

    unless File.exists?(source) do
      Mix.shell().error("Layout \"#{name}\" not found.")
      Mix.shell().info("")
      list_layouts()
      exit({:shutdown, 1})
    end

    dest_dir = Path.join(["themes", "custom", "layouts"])
    dest = Path.join(dest_dir, "#{name}.html.eex")

    if File.exists?(dest) do
      Mix.shell().error("Layout already exists at #{dest}")
      exit({:shutdown, 1})
    end

    File.mkdir_p!(dest_dir)
    File.cp!(source, dest)

    Mix.shell().info("#{IO.ANSI.green()}Copied#{IO.ANSI.reset()} #{name} layout to #{dest}")

    Mix.shell().info("")

    Mix.shell().info(
      "Remember to set #{IO.ANSI.cyan()}theme: \"custom\"#{IO.ANSI.reset()} in config/config.exs"
    )
  end

  defp list_layouts do
    layouts_dir = Sayfa.Config.default_theme_path("layouts")

    layouts =
      layouts_dir
      |> File.ls!()
      |> Enum.filter(&String.ends_with?(&1, ".html.eex"))
      |> Enum.map(&String.replace_suffix(&1, ".html.eex", ""))
      |> Enum.sort()

    Mix.shell().info("Available layouts:")
    Mix.shell().info("")

    Enum.each(layouts, fn layout ->
      Mix.shell().info("  #{layout}")
    end)
  end
end
