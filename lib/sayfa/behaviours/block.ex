defmodule Sayfa.Behaviours.Block do
  @moduledoc """
  Behaviour for defining reusable template blocks.

  A block is a reusable EEx component that renders HTML. Blocks are invoked
  in templates via the `@block` helper function:

      <%= @block.(:hero, title: "Welcome", subtitle: "My blog") %>
      <%= @block.(:recent_posts, limit: 5) %>

  ## Assigns

  The `render/1` callback receives a map of assigns that always includes:

  - `:site` — the resolved site config map
  - `:content` — the current `Sayfa.Content` struct (may be `nil` for list pages)
  - `:contents` — list of all site contents (for blocks like `recent_posts`)
  - `:lang` — the current language atom

  Plus any additional options passed by the template caller.

  ## Examples

      defmodule MyApp.Blocks.Banner do
        @behaviour Sayfa.Behaviours.Block

        @impl true
        def name, do: :banner

        @impl true
        def render(assigns) do
          text = Map.get(assigns, :text, "Welcome!")
          ~s(<div class="banner">\#{text}</div>)
        end
      end

  """

  @doc "Atom identifier for this block."
  @callback name() :: atom()

  @doc "Renders the block to an HTML string given assigns."
  @callback render(assigns :: map()) :: String.t()
end
