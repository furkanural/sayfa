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
      |> maybe_put(:verbose, opts[:verbose])

    verbose = Keyword.get(opts, :verbose, false)

    if verbose, do: Mix.shell().info("Building site...")

    case Sayfa.Builder.build(build_opts) do
      {:ok, result} ->
        Mix.shell().info(
          "Build complete: #{result.content_count} files → #{result.files_written} pages (#{result.elapsed_ms}ms)"
        )

      {:error, reason} ->
        Mix.shell().error("Build failed: #{format_error(reason)}")
        exit({:shutdown, 1})
    end
  end

  defp maybe_put(opts, _key, nil), do: opts
  defp maybe_put(opts, key, value), do: Keyword.put(opts, key, value)

  @doc false
  def format_error({:content_dir_not_found, dir}) do
    "Content directory not found: #{dir}"
  end

  def format_error({:parse_error, file, {:yaml_error, reason}}) do
    "YAML parse error in #{file}: #{inspect(reason)}"
  end

  def format_error({:parse_error, file, :missing_title}) do
    "Missing required 'title' in front matter: #{file}"
  end

  def format_error({:parse_error, file, reason}) do
    "Failed to parse #{file}: #{inspect(reason)}"
  end

  def format_error({:template_error, file, reason}) do
    "Template error in #{file}: #{inspect(reason)}"
  end

  def format_error(reason) do
    inspect(reason)
  end
end
