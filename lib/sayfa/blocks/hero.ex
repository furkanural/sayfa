defmodule Sayfa.Blocks.Hero do
  @moduledoc """
  Hero section block.

  Renders a prominent hero section with a title and optional subtitle.

  ## Assigns

  - `:title` — hero heading text (required)
  - `:subtitle` — optional subtitle text

  ## Examples

      <%= @block.(:hero, title: "Welcome", subtitle: "My blog") %>

  """

  @behaviour Sayfa.Behaviours.Block

  alias Sayfa.Block

  @impl true
  def name, do: :hero

  @impl true
  def render(assigns) do
    title = Block.escape_html(Map.get(assigns, :title, ""))
    subtitle = Map.get(assigns, :subtitle)

    subtitle_html =
      if subtitle do
        "\n  <p>#{Block.escape_html(subtitle)}</p>"
      else
        ""
      end

    "<section class=\"hero\">\n  <h1>#{title}</h1>#{subtitle_html}\n</section>"
  end
end
