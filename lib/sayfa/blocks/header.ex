defmodule Sayfa.Blocks.Header do
  @moduledoc """
  Site header block.

  Renders a `<header>` with the site title and optional navigation links.

  ## Assigns

  - `:site` — site config map (used for title)
  - `:nav` — list of `{label, url}` tuples for navigation (optional)

  ## Examples

      <%= @block.(:header, nav: [{"Home", "/"}, {"About", "/about/"}]) %>

  """

  @behaviour Sayfa.Behaviours.Block

  alias Sayfa.Block

  @impl true
  def name, do: :header

  @impl true
  def render(assigns) do
    site = Map.get(assigns, :site, %{})
    site_title = Block.escape_html(Map.get(site, :title, ""))
    nav = Map.get(assigns, :nav, [])

    nav_html =
      if nav != [] do
        items =
          Enum.map_join(nav, "\n    ", fn {label, url} ->
            "<li><a href=\"#{Block.escape_html(url)}\">#{Block.escape_html(label)}</a></li>"
          end)

        "\n  <nav>\n    <ul>\n    #{items}\n    </ul>\n  </nav>"
      else
        ""
      end

    "<header>\n  <a href=\"/\">#{site_title}</a>#{nav_html}\n</header>"
  end
end
