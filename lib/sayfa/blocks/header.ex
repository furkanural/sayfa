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
  alias Sayfa.Blocks.LanguageSwitcher
  alias Sayfa.Blocks.Search

  @impl true
  def name, do: :header

  @impl true
  def render(assigns) do
    site = Map.get(assigns, :site, %{})
    site_title = Block.escape_html(Map.get(site, :title, ""))
    nav = Map.get(assigns, :nav, [])
    page_url = Map.get(assigns, :page_url)
    lang_switcher = LanguageSwitcher.render(assigns)
    search_trigger = Search.render_trigger(assigns)

    lang = Map.get(assigns, :lang)
    default_lang = Map.get(site, :default_lang, :en)
    lang_prefix = if lang && lang != default_lang, do: "/#{lang}", else: ""
    home_url = if lang_prefix == "", do: "/", else: "#{lang_prefix}/"

    nav = prefix_nav_urls(nav, lang_prefix)
    nav_html = render_nav(nav, search_trigger, lang_switcher, page_url)

    """
    <header class="sticky top-0 z-50 border-b border-slate-200/80 dark:border-slate-800 bg-white/85 dark:bg-slate-900/85 backdrop-blur-lg">\
      <div class="max-w-3xl mx-auto px-5 sm:px-6">\
        <div class="flex items-center justify-between h-14">\
          <a href="#{home_url}" class="text-lg font-bold text-slate-900 dark:text-slate-100 hover:text-primary dark:hover:text-primary-400">#{site_title}</a>\
    #{nav_html}\
        </div>\
      </div>\
    </header>\
    """
  end

  defp prefix_nav_urls(nav, ""), do: nav

  defp prefix_nav_urls(nav, lang_prefix) do
    Enum.map(nav, fn {label, url} ->
      if String.starts_with?(url, "/") and not String.starts_with?(url, lang_prefix <> "/") do
        {label, lang_prefix <> url}
      else
        {label, url}
      end
    end)
  end

  defp render_nav([], "", "", _page_url), do: ""

  defp render_nav([], search_trigger, lang_switcher, _page_url) do
    """
          <div class="flex items-center">#{search_trigger}#{lang_switcher}</div>\
    """
  end

  defp render_nav(nav, search_trigger, lang_switcher, page_url) do
    desktop_items =
      Enum.map_join(nav, "", fn {label, url} ->
        classes =
          if active?(url, page_url) do
            "text-sm font-medium text-slate-900 dark:text-slate-100"
          else
            "text-sm text-slate-500 dark:text-slate-400 hover:text-slate-900 dark:hover:text-slate-100"
          end

        "<a href=\"#{Block.escape_html(url)}\" class=\"#{classes}\">#{Block.escape_html(label)}</a>"
      end)

    mobile_items =
      Enum.map_join(nav, "", fn {label, url} ->
        classes =
          if active?(url, page_url) do
            "flex items-center gap-3 py-2.5 text-sm font-medium text-primary dark:text-primary-400"
          else
            "flex items-center gap-3 py-2.5 text-sm text-slate-600 dark:text-slate-300 hover:text-primary dark:hover:text-primary-400"
          end

        "<a href=\"#{Block.escape_html(url)}\" class=\"#{classes}\">#{Block.escape_html(label)}</a>"
      end)

    """
          <div class="flex items-center gap-2">\
            <nav class="hidden md:flex items-center gap-7">#{desktop_items}</nav>\
    #{search_trigger}\
    #{lang_switcher}\
            <button id="menu-toggle" class="md:hidden p-2 -mr-2 text-slate-500 dark:text-slate-400 hover:text-slate-900 dark:hover:text-slate-100" aria-label="Toggle menu" aria-expanded="false" aria-controls="mobile-menu">\
              <svg class="w-5 h-5 menu-open" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24" aria-hidden="true"><line x1="4" x2="20" y1="6" y2="6"/><line x1="4" x2="20" y1="12" y2="12"/><line x1="4" x2="20" y1="18" y2="18"/></svg>\
              <svg class="w-5 h-5 menu-close hidden" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24" aria-hidden="true"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>\
            </button>\
          </div>\
        </div>\
        <nav id="mobile-menu" class="hidden pb-4 md:hidden">\
          <div class="flex flex-col gap-1 pt-2 border-t border-slate-200/80 dark:border-slate-800">#{mobile_items}</div>\
        </nav>\
    """
  end

  defp active?(_nav_url, nil), do: false

  defp active?(nav_url, page_url) do
    if home_url?(nav_url) do
      page_url == nav_url
    else
      String.starts_with?(page_url, nav_url)
    end
  end

  defp home_url?("/"), do: true
  defp home_url?(url), do: Regex.match?(~r"^/[a-z]{2}/$", url)
end
