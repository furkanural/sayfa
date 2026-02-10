defmodule Mix.Tasks.Sayfa.Build do
  @moduledoc """
  Builds the static site from content files.

  ## Usage

      mix sayfa.build [--source DIR] [--output DIR] [--drafts] [--verbose]

  ## Options

  - `--source` — content source directory (default: `content`)
  - `--output` — output directory (default: `output`)
  - `--drafts` — include draft content
  - `--verbose` — print detailed build information

  """

  use Mix.Task

  @shortdoc "Build the static site"

  @switches [
    source: :string,
    output: :string,
    drafts: :boolean,
    verbose: :boolean
  ]

  @impl Mix.Task
  def run(args) do
    {opts, _, _} = OptionParser.parse(args, switches: @switches)

    build_opts =
      []
      |> maybe_put(:content_dir, opts[:source])
      |> maybe_put(:output_dir, opts[:output])
      |> maybe_put(:drafts, opts[:drafts])

    verbose = Keyword.get(opts, :verbose, false)

    if verbose, do: Mix.shell().info("Building site...")

    case Sayfa.Builder.build(build_opts) do
      {:ok, result} ->
        Mix.shell().info(
          "Build complete: #{result.content_count} files → #{result.files_written} pages (#{result.elapsed_ms}ms)"
        )

      {:error, reason} ->
        Mix.shell().error("Build failed: #{inspect(reason)}")
        exit({:shutdown, 1})
    end
  end

  defp maybe_put(opts, _key, nil), do: opts
  defp maybe_put(opts, key, value), do: Keyword.put(opts, key, value)
end
