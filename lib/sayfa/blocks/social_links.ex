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

      "<div class=\"flex flex-wrap gap-3\">\n  #{items}\n</div>"
    end
  end

  defp render_link({label, url}) do
    icon = Block.social_icon(label, "w-5 h-5")
    escaped_label = Block.escape_html(label)
    escaped_url = Block.escape_html(url)
    rel = Block.social_rel(label)

    "<a href=\"#{escaped_url}\" rel=\"#{rel}\" class=\"btn-secondary gap-2 text-sm text-slate-600 dark:text-slate-300 hover:text-primary dark:hover:text-primary-400 bg-slate-50 dark:bg-slate-800/50\">#{icon} #{escaped_label}</a>"
  end
end
