defmodule Sayfa.SitemapTest do
  use ExUnit.Case, async: true
  doctest Sayfa.Sitemap

  alias Sayfa.Sitemap

  @config %{base_url: "https://example.com"}

  describe "generate/2" do
    test "generates valid sitemap XML" do
      urls = [
        %{loc: "/posts/hello/", lastmod: ~D[2024-01-15]},
        %{loc: "/about/", lastmod: nil}
      ]

      xml = Sitemap.generate(urls, @config)

      assert xml =~ ~s(<?xml version="1.0" encoding="utf-8"?>)
      assert xml =~ ~s(<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">)
    end

    test "includes full URLs" do
      urls = [%{loc: "/posts/hello/", lastmod: nil}]
      xml = Sitemap.generate(urls, @config)
      assert xml =~ "<loc>https://example.com/posts/hello/</loc>"
    end

    test "includes lastmod when present" do
      urls = [%{loc: "/posts/hello/", lastmod: ~D[2024-01-15]}]
      xml = Sitemap.generate(urls, @config)
      assert xml =~ "<lastmod>2024-01-15</lastmod>"
    end

    test "omits lastmod when nil" do
      urls = [%{loc: "/about/", lastmod: nil}]
      xml = Sitemap.generate(urls, @config)
      refute xml =~ "<lastmod>"
    end

    test "handles empty URL list" do
      xml = Sitemap.generate([], @config)
      assert xml =~ "<urlset"
      refute xml =~ "<url>"
    end

    test "handles trailing slash in base_url" do
      config = %{base_url: "https://example.com/"}
      urls = [%{loc: "/posts/hello/", lastmod: nil}]
      xml = Sitemap.generate(urls, config)
      assert xml =~ "<loc>https://example.com/posts/hello/</loc>"
    end
  end
end
