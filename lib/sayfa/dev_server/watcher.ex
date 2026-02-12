defmodule Sayfa.DevServer.Watcher do
  @moduledoc """
  GenServer that watches the filesystem for content changes.

  Uses the `:file_system` library to monitor content, theme, and config
  directories. When a relevant file changes, triggers a rebuild via
  `Sayfa.DevServer.Rebuilder`.
  """

  use GenServer

  alias Sayfa.DevServer.Rebuilder

  require Logger

  @relevant_extensions ~w(.md .eex .html .css .js .exs .yaml .yml .json)

  # --- Public API ---

  @doc """
  Starts the watcher.

  ## Options

  - `:dirs` — list of directories to watch
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  # --- Callbacks ---

  @impl true
  def init(opts) do
    dirs = Keyword.get(opts, :dirs, [])
    existing_dirs = Enum.filter(dirs, &File.dir?/1)

    case existing_dirs do
      [] ->
        Logger.warning("[sayfa] No directories to watch")
        {:ok, %{watcher_pid: nil}}

      watch_dirs ->
        {:ok, pid} = FileSystem.start_link(dirs: watch_dirs)
        FileSystem.subscribe(pid)
        Logger.info("[sayfa] Watching: #{Enum.join(watch_dirs, ", ")}")
        {:ok, %{watcher_pid: pid}}
    end
  end

  @impl true
  def handle_info({:file_event, _pid, {path, _events}}, state) do
    if relevant_file?(path) do
      Logger.debug("[sayfa] File changed: #{path}")
      Rebuilder.trigger_rebuild(path)
    end

    {:noreply, state}
  end

  def handle_info({:file_event, _pid, :stop}, state) do
    Logger.warning("[sayfa] File watcher stopped")
    {:noreply, state}
  end

  # --- Private ---

  @doc false
  def relevant_file?(path) do
    ext = Path.extname(path)
    ext in @relevant_extensions
  end
end
