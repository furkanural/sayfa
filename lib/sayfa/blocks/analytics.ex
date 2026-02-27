defmodule Sayfa.Blocks.Analytics do
  @moduledoc """
  Analytics tracking block.

  Renders provider-specific analytics script tags. Supports Google Analytics 4,
  Plausible, Fathom, and Umami. Returns an empty string when no analytics
  provider is configured.

  ## Configuration

  Set `analytics:` in your site config:

      config :sayfa, :site,
        analytics: [provider: :ga4, measurement_id: "G-XXXXXXXX"]

      config :sayfa, :site,
        analytics: [provider: :plausible, domain: "example.com"]

      config :sayfa, :site,
        analytics: [provider: :fathom, site_id: "ABCDEF"]

      config :sayfa, :site,
        analytics: [provider: :umami, website_id: "xxx", src: "https://umami.example.com/script.js"]

  ## Examples

      <%= @block.(:analytics, []) %>

  """

  @behaviour Sayfa.Behaviours.Block

  alias Sayfa.Block

  @impl true
  def name, do: :analytics

  @impl true
  def render(assigns) do
    site = Map.get(assigns, :site, %{})
    analytics = Map.get(site, :analytics)
    render_analytics(analytics)
  end

  defp render_analytics(nil), do: ""
  defp render_analytics([]), do: ""

  defp render_analytics(opts) when is_list(opts) do
    provider = Keyword.get(opts, :provider)
    render_provider(provider, opts)
  end

  defp render_analytics(_), do: ""

  defp render_provider(:ga4, opts) do
    measurement_id = opts |> Keyword.get(:measurement_id, "") |> Block.escape_html()

    if measurement_id == "" do
      ""
    else
      """
      <script async src="https://www.googletagmanager.com/gtag/js?id=#{measurement_id}"></script>
      <script>window.dataLayer=window.dataLayer||[];function gtag(){dataLayer.push(arguments)}gtag('js',new Date());gtag('config','#{measurement_id}');</script>
      """
    end
  end

  defp render_provider(:plausible, opts) do
    domain = opts |> Keyword.get(:domain, "") |> Block.escape_html()
    src = opts |> Keyword.get(:src, "https://plausible.io/js/script.js") |> Block.escape_html()

    if domain == "" do
      ""
    else
      ~s(<script defer data-domain="#{domain}" src="#{src}"></script>\n)
    end
  end

  defp render_provider(:fathom, opts) do
    site_id = opts |> Keyword.get(:site_id, "") |> Block.escape_html()

    if site_id == "" do
      ""
    else
      ~s(<script src="https://cdn.usefathom.com/script.js" data-site="#{site_id}" defer></script>\n)
    end
  end

  defp render_provider(:umami, opts) do
    website_id = opts |> Keyword.get(:website_id, "") |> Block.escape_html()
    src = opts |> Keyword.get(:src, "") |> Block.escape_html()

    if website_id == "" or src == "" do
      ""
    else
      ~s(<script async src="#{src}" data-website-id="#{website_id}"></script>\n)
    end
  end

  defp render_provider(_unknown, _opts), do: ""
end
