defmodule Sayfa.Blocks.Header do
  @moduledoc """
  Site header block.

  Renders a sticky header with glassmorphism backdrop-blur, the site title,
  and optional navigation links with a mobile hamburger menu.

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

    nav_html = render_nav(nav)

    """
    <header class="sticky top-0 z-50 border-b border-slate-200/80 dark:border-slate-800 bg-white/85 dark:bg-slate-900/85 backdrop-blur-lg">\
      <div class="max-w-3xl mx-auto px-5 sm:px-6">\
        <div class="flex items-center justify-between h-14">\
          <a href="/" class="text-lg font-bold text-slate-900 dark:text-slate-100 hover:text-primary dark:hover:text-primary-400">#{site_title}</a>\
    #{nav_html}\
        </div>\
      </div>\
    </header>\
    """
  end

  defp render_nav([]), do: ""

  defp render_nav(nav) do
    desktop_items =
      Enum.map_join(nav, "", fn {label, url} ->
        "<a href=\"#{Block.escape_html(url)}\" class=\"text-sm text-slate-500 dark:text-slate-400 hover:text-slate-900 dark:hover:text-slate-100\">#{Block.escape_html(label)}</a>"
      end)

    mobile_items =
      Enum.map_join(nav, "", fn {label, url} ->
        "<a href=\"#{Block.escape_html(url)}\" class=\"flex items-center gap-3 py-2.5 text-sm text-slate-600 dark:text-slate-300 hover:text-primary dark:hover:text-primary-400\">#{Block.escape_html(label)}</a>"
      end)

    """
          <nav class="hidden md:flex items-center gap-7">#{desktop_items}</nav>\
          <button id="menu-toggle" onclick="(function(){var m=document.getElementById('mobile-menu'),o=document.querySelector('.menu-open'),c=document.querySelector('.menu-close'),h=m.classList.contains('hidden');m.classList.toggle('hidden');o.classList.toggle('hidden',h);c.classList.toggle('hidden',!h)})()" class="md:hidden p-2 -mr-2 text-slate-500 dark:text-slate-400 hover:text-slate-900 dark:hover:text-slate-100" aria-label="Toggle menu">\
            <svg class="w-5 h-5 menu-open" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24"><line x1="4" x2="20" y1="6" y2="6"/><line x1="4" x2="20" y1="12" y2="12"/><line x1="4" x2="20" y1="18" y2="18"/></svg>\
            <svg class="w-5 h-5 menu-close hidden" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>\
          </button>\
        </div>\
        <nav id="mobile-menu" class="hidden pb-4 md:hidden">\
          <div class="flex flex-col gap-1 pt-2 border-t border-slate-200/80 dark:border-slate-800">#{mobile_items}</div>\
        </nav>\
    """
  end
end
