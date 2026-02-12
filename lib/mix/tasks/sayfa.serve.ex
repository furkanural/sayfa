defmodule Mix.Tasks.Sayfa.Serve do
  @moduledoc """
  Starts a development server with live reload.

  ## Usage

      mix sayfa.serve [--port PORT] [--source DIR] [--output DIR] [--no-drafts] [--verbose]

  ## Options

  - `--port` — HTTP port (default: `4000`)
  - `--source` — content source directory (default: `content`)
  - `--output` — output directory (default: `output`)
  - `--no-drafts` — exclude draft content (drafts are included by default in serve mode)
  - `--verbose` — print detailed build information

  ## Description

  Performs an initial build, then starts an HTTP server serving the output
  directory. Watches content, theme, and config directories for changes and
  automatically rebuilds + live-reloads the browser.

  Press Ctrl+C to stop.
  """

  use Mix.Task

  @shortdoc "Start dev server with live reload"
  @requirements ["app.start"]

  @switches [
    port: :integer,
    source: :string,
    output: :string,
    drafts: :boolean,
    verbose: :boolean
  ]

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    {opts, _, _} = OptionParser.parse(args, switches: @switches)

    port = Keyword.get(opts, :port, 4000)
    content_dir = Keyword.get(opts, :source, "content")
    output_dir = Keyword.get(opts, :output, "output")
    drafts = Keyword.get(opts, :drafts, true)
    verbose = Keyword.get(opts, :verbose, false)

    build_config = [
      content_dir: content_dir,
      output_dir: output_dir,
      drafts: drafts,
      verbose: verbose
    ]

    Mix.shell().info("Starting Sayfa dev server on http://localhost:#{port}")
    Mix.shell().info("Watching: #{content_dir}/")

    {:ok, _pid} =
      Sayfa.DevServer.Supervisor.start_link(
        config: build_config,
        port: port,
        output_dir: output_dir,
        content_dir: content_dir
      )

    Mix.shell().info("Dev server running. Press Ctrl+C to stop.")
    Process.sleep(:infinity)
  end
end
