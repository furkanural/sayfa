defmodule Sayfa.Blocks.Footer do
  @moduledoc """
  Site footer block.

  Renders a footer with copyright information, feed links, and icon-only social links.

  ## Assigns

  - `:year` — copyright year (defaults to current year)
  - `:author` — author name (falls back to `site.author` or `site.title`)
  - `:site` — site config map (used for author and social_links)
  - `:t` — translation function (injected by the template system)

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

    social_links = Map.get(site, :social_links, [])
    social_html = render_social_icons(social_links)
    t_fn = Map.get(assigns, :t, fn key -> key end)
    feed_html = render_feed_links(t_fn)

    """
    <footer class="site-footer">\
      <div class="footer-content container-content-wide">\
        <p class="footer-copy">&copy; #{year} #{Block.escape_html(to_string(author))}</p>\
    #{feed_html}\
    #{social_html}\
      </div>\
    </footer>\
    """
  end

  defp render_feed_links(_t_fn) do
    ~s(      <div class="feed-links footer-feed-links">) <>
      ~s(<a href="/feed.xml" class="footer-link">Atom</a>) <>
      ~s(<a href="/feed.json" class="footer-link">JSON</a></div>)
  end

  defp render_social_icons([]), do: ""

  defp render_social_icons(links) do
    items =
      Enum.map_join(links, "\n", fn {label, url} ->
        icon = Block.social_icon(label, "icon-5")
        escaped_label = Block.escape_html(label)
        escaped_url = Block.escape_html(url)
        rel = Block.social_rel(label)

        "          <a href=\"#{escaped_url}\" rel=\"#{rel}\" class=\"social-link footer-social-link\" aria-label=\"#{escaped_label}\">#{icon}</a>"
      end)

    "      <div class=\"social-links footer-social\">\n#{items}\n      </div>"
  end
end
