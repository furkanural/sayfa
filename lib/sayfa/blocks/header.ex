defmodule Sayfa.Blocks.Header do
  @moduledoc """
  Site header block.

  Renders a sticky header with glassmorphism backdrop-blur, the site title
  (or logo image), and optional navigation links with a mobile hamburger menu.

  ## Assigns

  - `:site` — site config map (used for title, logo, logo_dark)
  - `:nav` — list of `{label, url}` tuples for navigation (optional)

  ## Logo support

  Set `logo:` and optionally `logo_dark:` in your site config:

      config :sayfa, :site,
        logo: "/images/logo.svg",
        logo_dark: "/images/logo-dark.svg"

  When `logo` is set, an `<img>` is rendered instead of the plain text title.
  When both `logo` and `logo_dark` are set, the light logo is hidden in dark
  mode and the dark logo is shown (`dark:hidden` / `hidden dark:block`).

  ## Examples

      <%= @block.(:header, nav: [{"Home", "/"}, {"About", "/about/"}]) %>

  """

  @behaviour Sayfa.Behaviours.Block

  alias Sayfa.Block
  alias Sayfa.Blocks.LanguageSwitcher

  @impl true
  def name, do: :header

  @impl true
  def render(assigns) do
    site = Map.get(assigns, :site, %{})
    site_title = Block.escape_html(Map.get(site, :title, ""))
    logo = Map.get(site, :logo)
    logo_dark = Map.get(site, :logo_dark)
    nav = Map.get(assigns, :nav, [])
    page_url = Map.get(assigns, :page_url)

    lang_switcher = LanguageSwitcher.render(Map.put(assigns, :variant, :desktop))

    lang = Map.get(assigns, :lang)
    default_lang = Map.get(site, :default_lang, :en)
    lang_prefix = if lang && lang != default_lang, do: "/#{lang}", else: ""
    home_url = if lang_prefix == "", do: "/", else: "#{lang_prefix}/"

    nav = prefix_nav_urls(nav, lang_prefix)

    {brand_html, link_class} =
      if logo do
        img = render_logo_img(logo, logo_dark, site_title)
        {img, "header-brand-logo"}
      else
        {site_title, "header-brand-text"}
      end

    brand_link = ~s(<a href="#{home_url}" class="#{link_class}">#{brand_html}</a>)

    render_header(
      brand_link,
      nav,
      lang_switcher,
      page_url
    )
  end

  defp render_logo_img(logo, nil, alt) do
    ~s(<img src="#{Block.escape_html(logo)}" alt="#{alt}" class="header-logo" loading="eager">)
  end

  defp render_logo_img(logo, logo_dark, alt) do
    light =
      ~s(<img src="#{Block.escape_html(logo)}" alt="#{alt}" class="header-logo-light" loading="eager">)

    dark =
      ~s(<img src="#{Block.escape_html(logo_dark)}" alt="#{alt}" class="header-logo-dark" loading="eager">)

    light <> dark
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

  # Header with no nav links: brand on the left, language switcher (if any) on
  # the right.
  defp render_header(brand_link, [], lang_switcher, _page_url) do
    right =
      if lang_switcher == "" do
        ""
      else
        ~s(<div class="header-nav-right">#{lang_switcher}</div>)
      end

    """
    <header class="site-header">\
      <nav class="header-nav container-content-wide" aria-label="Primary">\
        <div class="header-nav-left">#{brand_link}</div>\
    #{right}\
      </nav>\
    </header>\
    """
  end

  defp render_header(brand_link, nav, lang_switcher, page_url) do
    desktop_items =
      Enum.map_join(nav, "", fn {label, url} ->
        {classes, attrs} =
          if active?(url, page_url) do
            {"nav-link active", " aria-current=\"page\""}
          else
            {"nav-link", ""}
          end

        "<a href=\"#{Block.escape_html(url)}\" class=\"#{classes}\"#{attrs}>#{Block.escape_html(label)}</a>"
      end)

    mobile_items =
      Enum.map_join(nav, "", fn {label, url} ->
        {classes, attrs} =
          if active?(url, page_url) do
            {"header-mobile-link-active", " aria-current=\"page\""}
          else
            {"header-mobile-link", ""}
          end

        "<a href=\"#{Block.escape_html(url)}\" class=\"#{classes}\"#{attrs}>#{Block.escape_html(label)}</a>"
      end)

    """
    <header class="site-header">\
      <nav class="header-nav container-content-wide" aria-label="Primary">\
        <div class="header-nav-left">\
          #{brand_link}\
          <div class="nav-menu header-desktop-nav">#{desktop_items}</div>\
        </div>\
        <div class="header-nav-right">\
          #{lang_switcher}\
          <button id="menu-toggle" class="mobile-menu-toggle" aria-label="Toggle menu" aria-expanded="false" aria-controls="mobile-menu">\
            <svg class="icon-menu menu-open" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24" aria-hidden="true"><line x1="4" x2="20" y1="6" y2="6"/><line x1="4" x2="20" y1="12" y2="12"/><line x1="4" x2="20" y1="18" y2="18"/></svg>\
            <svg class="icon-menu menu-close hidden" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24" aria-hidden="true"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>\
          </button>\
        </div>\
      </nav>\
      <nav id="mobile-menu" class="nav-menu header-mobile-menu hidden" aria-label="Mobile primary">\
        <div class="header-mobile-list">#{mobile_items}</div>\
      </nav>\
    </header>\
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
