defmodule Sayfa.Behaviours.Hook do
  @moduledoc """
  Behaviour for defining build pipeline hooks.

  Hooks allow extending the build pipeline at four stages:

  - `:before_parse` — receives a `Sayfa.Content.Raw` struct before Markdown rendering
  - `:after_parse` — receives a `Sayfa.Content` struct after parsing
  - `:before_render` — receives a `Sayfa.Content` struct before template rendering
  - `:after_render` — receives a `{Sayfa.Content.t(), html_string}` tuple after rendering

  Hooks are registered via application config:

      config :sayfa, :hooks, [MyApp.Hooks.InjectAnalytics]

  Hooks run sequentially in the order they are registered. If any hook
  returns `{:error, reason}`, the pipeline halts.

  ## Examples

      defmodule MyApp.Hooks.InjectAnalytics do
        @behaviour Sayfa.Behaviours.Hook

        @impl true
        def stage, do: :after_render

        @impl true
        def run({content, html}, _opts) do
          {:ok, {content, html <> "<script>/* analytics */</script>"}}
        end
      end

  """

  @doc "The pipeline stage at which this hook runs."
  @callback stage() :: :before_parse | :after_parse | :before_render | :after_render

  @doc "Runs the hook on the given content at the configured stage."
  @callback run(content :: term(), opts :: map()) :: {:ok, term()} | {:error, term()}
end
