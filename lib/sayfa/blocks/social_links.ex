defmodule Sayfa.Blocks.SocialLinks do
  @moduledoc """
  Social links block.

  Renders card-style social media links with platform icons.

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
      items = Enum.map_join(links, "\n  ", &render_link/1)

      "<div class=\"social-links-wrap\">\n  #{items}\n</div>"
    end
  end

  defp render_link({label, url}) do
    icon = Block.social_icon(label, "icon-5")
    escaped_label = Block.escape_html(label)
    escaped_url = Block.escape_html(url)
    rel = Block.social_rel(label)

    "<a href=\"#{escaped_url}\" rel=\"#{rel}\" class=\"social-link-btn\">#{icon} #{escaped_label}</a>"
  end
end
