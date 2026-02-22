defmodule Sayfa.Blocks.Hero do
  @moduledoc """
  Hero section block.

  Renders a minimal, left-aligned hero section with a large title
  and optional subtitle.

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
      if subtitle && subtitle != "" do
        "<p class=\"mt-4 text-base sm:text-lg text-slate-500 dark:text-slate-400 leading-relaxed max-w-xl\">#{Block.escape_html(subtitle)}</p>"
      else
        ""
      end

    """
    <h1 class="text-3xl sm:text-4xl font-bold text-slate-900 dark:text-slate-50">#{title}</h1>\
    #{subtitle_html}\
    """
  end
end
