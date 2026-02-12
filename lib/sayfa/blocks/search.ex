defmodule Sayfa.Blocks.Search do
  @moduledoc """
  Pagefind search UI block.

  Renders the Pagefind search interface with its CSS, JS, and container element.

  ## Assigns

  - `:element` — CSS selector for the container (default: `"#search"`)
  - `:show_sub_results` — show sub-results in search (default: `true`)
  - `:show_images` — show images in results (default: `true`)

  ## Examples

      <%= @block.(:search) %>
      <%= @block.(:search, show_images: false) %>

  """

  @behaviour Sayfa.Behaviours.Block

  @impl true
  def name, do: :search

  @impl true
  def render(assigns) do
    element = Map.get(assigns, :element, "#search")
    show_sub_results = Map.get(assigns, :show_sub_results, true)
    show_images = Map.get(assigns, :show_images, true)

    """
    <link href="/pagefind/pagefind-ui.css" rel="stylesheet">
    <script src="/pagefind/pagefind-ui.js"></script>
    <div id="search"></div>
    <script>new PagefindUI({ element: "#{element}", showSubResults: #{show_sub_results}, showImages: #{show_images} });</script>\
    """
  end
end
