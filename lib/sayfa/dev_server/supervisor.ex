defmodule Sayfa.DevServer.Supervisor do
  @moduledoc """
  Supervisor for the Sayfa dev server components.

  Starts in order: Rebuilder → Watcher → Cowboy HTTP server.
  This supervisor is started by `mix sayfa.serve`, not in `application.ex`.
  """

  use Supervisor

  @doc """
  Starts the dev server supervisor.

  ## Options

  - `:config` — keyword list of build options
  - `:port` — HTTP port (default: 4000)
  - `:output_dir` — directory to serve (default: "dist")
  - `:content_dir` — content directory to watch (default: "content")
  """
  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    config = Keyword.get(opts, :config, [])
    port = Keyword.get(opts, :port, 4000)
    output_dir = Keyword.get(opts, :output_dir, "dist")
    content_dir = Keyword.get(opts, :content_dir, "content")

    watch_dirs =
      [content_dir, "themes", "config"]
      |> Enum.filter(&File.dir?/1)

    children = [
      {Sayfa.DevServer.Rebuilder, config: config},
      {Sayfa.DevServer.Watcher, dirs: watch_dirs},
      {Plug.Cowboy,
       scheme: :http,
       plug: {Sayfa.DevServer.Plug, [output_dir: output_dir]},
       options: [port: port]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
