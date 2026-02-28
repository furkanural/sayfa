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
    <footer class="border-t border-slate-200/70 dark:border-slate-800">\
      <div class="max-w-3xl mx-auto px-5 sm:px-6 py-8">\
        <div class="flex flex-col sm:flex-row items-center justify-between gap-4">\
          <div class="flex items-center gap-3">\
            <p class="text-sm text-slate-400 dark:text-slate-500">&copy; #{year} #{Block.escape_html(to_string(author))}</p>\
    #{feed_html}\
          </div>\
    #{social_html}\
        </div>\
      </div>\
    </footer>\
    """
  end

  defp render_feed_links(t_fn) do
    atom_label = Block.escape_html(t_fn.("subscribe_via_atom"))
    json_label = Block.escape_html(t_fn.("subscribe_via_json"))
    link = "hover:text-primary dark:hover:text-primary-400 transition-colors"

    tooltip =
      "pointer-events-none absolute bottom-full left-1/2 -translate-x-1/2 mb-1.5 rounded " <>
        "bg-slate-800 dark:bg-slate-700 px-2 py-0.5 text-xs text-white " <>
        "whitespace-nowrap opacity-0 group-hover:opacity-100 transition-opacity z-10"

    rss_icon =
      ~s(<svg class="w-3.5 h-3.5 shrink-0" viewBox="0 0 24 24" fill="none" ) <>
        ~s(stroke="currentColor" stroke-width="2" aria-hidden="true">) <>
        ~s(<path d="M4 11a9 9 0 0 1 9 9"/>) <>
        ~s(<path d="M4 4a16 16 0 0 1 16 16"/>) <>
        ~s(<circle cx="5" cy="19" r="1" fill="currentColor" stroke="none"/></svg>)

    ~s(          <div class="flex items-center gap-1.5 text-xs text-slate-400 dark:text-slate-500">) <>
      rss_icon <>
      ~s(<span class="relative group">) <>
      ~s(<a href="/feed.xml" class="#{link}">Atom</a>) <>
      ~s(<span class="#{tooltip}">#{atom_label}</span></span>) <>
      ~s(<span class="opacity-50">·</span>) <>
      ~s(<span class="relative group">) <>
      ~s(<a href="/feed.json" class="#{link}">JSON</a>) <>
      ~s(<span class="#{tooltip}">#{json_label}</span></span></div>)
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
