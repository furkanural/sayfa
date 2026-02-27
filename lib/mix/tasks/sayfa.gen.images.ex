defmodule Mix.Tasks.Sayfa.Gen.Images do
  @moduledoc """
  Scaffolds an image optimization pipeline into your project.

  ## Usage

      mix sayfa.gen.images

  ## What it creates

  - `scripts/optimize_images.sh` — shell script using vips or ImageMagick
  - `IMAGES.md` — documentation for image optimization workflow

  Run the script after adding images to `static/images/`:

      bash scripts/optimize_images.sh

  See `IMAGES.md` for details on required tools and optional Elixir-native
  processing with the `image` hex package.
  """

  use Mix.Task

  @shortdoc "Scaffold image optimization pipeline"

  @impl Mix.Task
  def run(_args) do
    copy_template("optimize.sh", "scripts/optimize_images.sh", executable: true)
    copy_template("IMAGES.md", "IMAGES.md")
  end

  defp copy_template(source_name, dest_path, opts \\ []) do
    source =
      Path.join([to_string(:code.priv_dir(:sayfa)), "templates", "gen_images", source_name])

    if File.exists?(dest_path) do
      Mix.shell().error("File already exists: #{dest_path}")
      exit({:shutdown, 1})
    end

    File.mkdir_p!(Path.dirname(dest_path))
    File.cp!(source, dest_path)

    if Keyword.get(opts, :executable, false) do
      File.chmod!(dest_path, 0o755)
    end

    Mix.shell().info("#{IO.ANSI.green()}Created#{IO.ANSI.reset()} #{dest_path}")
  end
end
