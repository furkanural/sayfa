defmodule Sayfa.Blocks.Footer do
  @moduledoc """
  Site footer block.

  Renders a `<footer>` with copyright information.

  ## Assigns

  - `:year` — copyright year (defaults to current year)
  - `:author` — author name (falls back to `site.author` or `site.title`)
  - `:site` — site config map

  ## Examples

      <%= @block.(:footer, author: "Jane Doe") %>

  """

  @behaviour Sayfa.Behaviours.Block

  alias Sayfa.Block

  @impl true
  def name, do: :footer

  @impl true
  def render(assigns) do
    site = Map.get(assigns, :site, %{})
    year = Map.get(assigns, :year, Date.utc_today().year)

    author =
      Map.get(assigns, :author) ||
        Map.get(site, :author) ||
        Map.get(site, :title, "")

    "<footer>\n  <p>&copy; #{year} #{Block.escape_html(to_string(author))}</p>\n</footer>"
  end
end
