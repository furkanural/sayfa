defmodule Mix.Tasks.Sayfa.Clean do
  @moduledoc """
  Removes the build output directory.

  ## Usage

      mix sayfa.clean [--output dir]

  ## Options

  - `--output` — output directory to clean (default: `"dist"`)

  ## Examples

      mix sayfa.clean
      mix sayfa.clean --output dist

  """

  use Mix.Task

  @shortdoc "Remove the build output directory"

  @switches [
    output: :string
  ]

  @impl Mix.Task
  def run(args) do
    {opts, _} = OptionParser.parse!(args, switches: @switches)
    output_dir = Keyword.get(opts, :output, "dist")

    Mix.Task.run("app.start")
    Sayfa.Builder.clean(output_dir: output_dir)
    Mix.shell().info("Cleaned #{output_dir}")
  end
end
