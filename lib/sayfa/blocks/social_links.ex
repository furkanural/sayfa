defmodule Sayfa.Blocks.SocialLinks do
  @moduledoc """
  Social links block.

  Renders a list of social media links.

  ## Assigns

  - `:links` — list of `{name, url}` tuples (required)

  ## Examples

      <%= @block.(:social_links, links: [{"GitHub", "https://github.com/me"}, {"Twitter", "https://twitter.com/me"}]) %>

  """

  @behaviour Sayfa.Behaviours.Block

  alias Sayfa.Block

  @impl true
  def name, do: :social_links

  @impl true
  def render(assigns) do
    links = Map.get(assigns, :links, [])

    if links == [] do
      ""
    else
      items =
        Enum.map_join(links, "\n  ", fn {label, url} ->
          "<li><a href=\"#{Block.escape_html(url)}\" rel=\"noopener\">#{Block.escape_html(label)}</a></li>"
        end)

      "<ul class=\"social-links\">\n  #{items}\n</ul>"
    end
  end
end
