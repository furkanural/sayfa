defmodule Sayfa.Sitemap do
  @moduledoc """
  Generates XML sitemaps for search engine discovery.

  Produces a standard sitemap.xml with `<urlset>`, `<url>`, `<loc>`,
  and optional `<lastmod>` elements.

  ## Examples

      urls = [%{loc: "/posts/hello/", lastmod: ~D[2024-01-15]}, %{loc: "/about/", lastmod: nil}]
      config = %{base_url: "https://example.com"}
      xml = Sayfa.Sitemap.generate(urls, config)

  """

  @doc """
  Generates a sitemap XML string.

  Takes a list of URL maps and site config. Each URL map should have:
  - `:loc` — the path (e.g., `"/posts/hello/"`)
  - `:lastmod` — a `Date` or `nil`

  ## Examples

      iex> urls = [%{loc: "/posts/hello/", lastmod: ~D[2024-01-15]}, %{loc: "/about/", lastmod: nil}]
      iex> config = %{base_url: "https://example.com"}
      iex> xml = Sayfa.Sitemap.generate(urls, config)
      iex> xml =~ "https://example.com/posts/hello/"
      true
      iex> xml =~ "<lastmod>2024-01-15</lastmod>"
      true
      iex> xml =~ "https://example.com/about/"
      true

  """
  @spec generate([%{loc: String.t(), lastmod: Date.t() | nil}], map()) :: String.t()
  def generate(urls, config) do
    base_url = String.trim_trailing(config.base_url, "/")

    url_elements =
      Enum.map(urls, fn url_entry ->
        children =
          [XmlBuilder.element(:loc, "#{base_url}#{url_entry.loc}")] ++
            lastmod_element(url_entry.lastmod)

        XmlBuilder.element(:url, children)
      end)

    urlset =
      XmlBuilder.element(
        :urlset,
        %{xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9"},
        url_elements
      )

    XmlBuilder.generate(urlset, format: :none)
    |> prepend_xml_declaration()
  end

  defp lastmod_element(nil), do: []

  defp lastmod_element(%Date{} = date) do
    [XmlBuilder.element(:lastmod, Date.to_iso8601(date))]
  end

  defp prepend_xml_declaration(xml) do
    ~s(<?xml version="1.0" encoding="utf-8"?>) <> xml
  end
end
