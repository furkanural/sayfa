defmodule Sayfa.Blocks.Footer do
  @moduledoc """
  Site footer block.

  Renders a footer with copyright information and icon-only social links.

  ## Assigns

  - `:year` — copyright year (defaults to current year)
  - `:author` — author name (falls back to `site.author` or `site.title`)
  - `:site` — site config map (used for author and social_links)

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

    """
    <footer class="border-t border-slate-200/70 dark:border-slate-800">\
      <div class="max-w-3xl mx-auto px-5 sm:px-6 py-8">\
        <div class="flex flex-col sm:flex-row items-center justify-between gap-4">\
          <p class="text-sm text-slate-400 dark:text-slate-500">&copy; #{year} #{Block.escape_html(to_string(author))}</p>\
    #{social_html}\
        </div>\
      </div>\
    </footer>\
    """
  end

  defp render_social_icons([]), do: ""

  defp render_social_icons(links) do
    items =
      Enum.map_join(links, "\n", fn {label, url} ->
        icon = Block.social_icon(label, "w-5 h-5")
        escaped_label = Block.escape_html(label)
        escaped_url = Block.escape_html(url)
        rel = Block.social_rel(label)

        "          <a href=\"#{escaped_url}\" rel=\"#{rel}\" class=\"text-slate-400 dark:text-slate-500 hover:text-primary dark:hover:text-primary-400\" aria-label=\"#{escaped_label}\">#{icon}</a>"
      end)

    "      <div class=\"flex items-center gap-4\">\n#{items}\n      </div>"
  end
end
