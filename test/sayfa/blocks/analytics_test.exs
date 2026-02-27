defmodule Sayfa.Blocks.AnalyticsTest do
  use ExUnit.Case, async: true

  alias Sayfa.Blocks.Analytics

  defp assigns(analytics_opts) do
    %{site: %{analytics: analytics_opts}}
  end

  describe "name/0" do
    test "returns :analytics" do
      assert Analytics.name() == :analytics
    end
  end

  describe "render/1 — GA4" do
    test "renders gtag script tags" do
      html = Analytics.render(assigns(provider: :ga4, measurement_id: "G-ABC123"))

      assert html =~ "googletagmanager.com/gtag/js?id=G-ABC123"
      assert html =~ "gtag('config','G-ABC123')"
    end

    test "returns empty string when measurement_id is missing" do
      html = Analytics.render(assigns(provider: :ga4))
      assert html == ""
    end
  end

  describe "render/1 — Plausible" do
    test "renders plausible script tag" do
      html = Analytics.render(assigns(provider: :plausible, domain: "example.com"))

      assert html =~ ~s(data-domain="example.com")
      assert html =~ "plausible.io/js/script.js"
    end

    test "supports custom src for self-hosted" do
      html =
        Analytics.render(
          assigns(
            provider: :plausible,
            domain: "example.com",
            src: "https://stats.example.com/js/script.js"
          )
        )

      assert html =~ "stats.example.com/js/script.js"
    end

    test "returns empty string when domain is missing" do
      html = Analytics.render(assigns(provider: :plausible))
      assert html == ""
    end
  end

  describe "render/1 — Fathom" do
    test "renders fathom script tag" do
      html = Analytics.render(assigns(provider: :fathom, site_id: "ABCDEF"))

      assert html =~ "cdn.usefathom.com/script.js"
      assert html =~ ~s(data-site="ABCDEF")
    end

    test "returns empty string when site_id is missing" do
      html = Analytics.render(assigns(provider: :fathom))
      assert html == ""
    end
  end

  describe "render/1 — Umami" do
    test "renders umami script tag" do
      html =
        Analytics.render(
          assigns(
            provider: :umami,
            website_id: "abc-123",
            src: "https://umami.example.com/script.js"
          )
        )

      assert html =~ ~s(data-website-id="abc-123")
      assert html =~ "umami.example.com/script.js"
    end

    test "returns empty string when src is missing" do
      html = Analytics.render(assigns(provider: :umami, website_id: "abc-123"))
      assert html == ""
    end

    test "returns empty string when website_id is missing" do
      html =
        Analytics.render(assigns(provider: :umami, src: "https://umami.example.com/script.js"))

      assert html == ""
    end
  end

  describe "render/1 — unknown/missing provider" do
    test "returns empty string for unknown provider" do
      html = Analytics.render(assigns(provider: :unknown_analytics))
      assert html == ""
    end

    test "returns empty string when analytics config is nil" do
      html = Analytics.render(%{site: %{}})
      assert html == ""
    end

    test "returns empty string when site is missing" do
      html = Analytics.render(%{})
      assert html == ""
    end

    test "returns empty string when analytics is empty list" do
      html = Analytics.render(%{site: %{analytics: []}})
      assert html == ""
    end
  end

  describe "HTML escaping" do
    test "escapes dangerous values in GA4 measurement_id" do
      html =
        Analytics.render(assigns(provider: :ga4, measurement_id: "<script>alert(1)</script>"))

      refute html =~ "<script>alert(1)</script>"
      assert html =~ "&lt;script&gt;"
    end

    test "escapes dangerous values in plausible domain" do
      html = Analytics.render(assigns(provider: :plausible, domain: "example.com\"><script>"))
      refute html =~ "<script>"
    end
  end
end
