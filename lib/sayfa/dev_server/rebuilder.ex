defmodule Sayfa.DevServer.Rebuilder do
  @moduledoc """
  GenServer that manages debounced site rebuilds.

  Tracks a `build_id` counter that increments after each successful build.
  The dev server Plug polls this value for live reload detection.
  """

  use GenServer

  require Logger

  @debounce_ms 200

  # --- Public API ---

  @doc """
  Starts the rebuilder.

  ## Options

  - `:config` — keyword list of build options passed to `Sayfa.Builder.build/1`
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Triggers a rebuild. Multiple calls within the debounce window are coalesced.
  """
  @spec trigger_rebuild(String.t()) :: :ok
  def trigger_rebuild(reason \\ "file changed") do
    GenServer.cast(__MODULE__, {:trigger_rebuild, reason})
  end

  @doc """
  Returns the current build ID (incremented after each successful build).
  """
  @spec build_id() :: non_neg_integer()
  def build_id do
    GenServer.call(__MODULE__, :build_id)
  end

  # --- Callbacks ---

  @impl true
  def init(opts) do
    config = Keyword.get(opts, :config, [])

    state = %{
      config: config,
      build_id: 0,
      content_cache: %{},
      timer_ref: nil
    }

    # Run initial build
    state = do_build(state)

    {:ok, state}
  end

  @impl true
  def handle_cast({:trigger_rebuild, _reason}, state) do
    state = schedule_rebuild(state)
    {:noreply, state}
  end

  @impl true
  def handle_call(:build_id, _from, state) do
    {:reply, state.build_id, state}
  end

  @impl true
  def handle_info(:do_rebuild, state) do
    state = %{state | timer_ref: nil}
    state = do_build(state)
    {:noreply, state}
  end

  # --- Private ---

  defp schedule_rebuild(%{timer_ref: nil} = state) do
    ref = Process.send_after(self(), :do_rebuild, @debounce_ms)
    %{state | timer_ref: ref}
  end

  defp schedule_rebuild(%{timer_ref: old_ref} = state) do
    Process.cancel_timer(old_ref)
    ref = Process.send_after(self(), :do_rebuild, @debounce_ms)
    %{state | timer_ref: ref}
  end

  defp do_build(state) do
    build_opts = Keyword.merge(state.config, content_cache: state.content_cache)

    case Sayfa.Builder.build(build_opts) do
      {:ok, result} ->
        new_id = state.build_id + 1
        Logger.info("[sayfa] Rebuild ##{new_id} complete (#{result.elapsed_ms}ms)")
        %{state | build_id: new_id, content_cache: result.content_cache}

      {:error, reason} ->
        Logger.error("[sayfa] Rebuild failed: #{inspect(reason)}")
        state
    end
  end
end
