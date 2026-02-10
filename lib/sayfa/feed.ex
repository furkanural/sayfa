defmodule Sayfa.Feed do
  @moduledoc """
  Generates Atom feeds from content.

  Produces standard Atom XML feeds for syndication. Generates a main feed
  for all dated content and per-type feeds for specific content types.

  ## Examples

      contents = [%Sayfa.Content{title: "Hello", body: "<p>World</p>", date: ~D[2024-01-15], slug: "hello", meta: %{"url_prefix" => "posts"}}]
      config = %{title: "My Site", base_url: "https://example.com", author: "Author"}
      xml = Sayfa.Feed.generate(contents, config)

  """

  alias Sayfa.Content

  @doc """
  Generates an Atom XML feed string for all dated content.

  Contents are sorted by date descending (newest first).
  Contents without a date are excluded.

  ## Examples

      iex> contents = [%Sayfa.Content{title: "Hello", body: "<p>World</p>", date: ~D[2024-01-15], slug: "hello", meta: %{"url_prefix" => "posts"}}]
      iex> config = %{title: "My Site", base_url: "https://example.com", author: "Author"}
      iex> xml = Sayfa.Feed.generate(contents, config)
      iex> xml =~ "<feed"
      true
      iex> xml =~ "Hello"
      true

  """
  @spec generate([Content.t()], map()) :: String.t()
  def generate(contents, config) do
    contents
    |> Enum.filter(& &1.date)
    |> Content.sort_by_date(:desc)
    |> build_feed(config, "/feed.xml")
  end

  @doc """
  Generates an Atom XML feed for a specific content type.

  Filters contents by the given type name before generating.

  ## Examples

      iex> contents = [
      ...>   %Sayfa.Content{title: "Post", body: "<p>A</p>", date: ~D[2024-01-15], slug: "post", meta: %{"content_type" => "posts", "url_prefix" => "posts"}},
      ...>   %Sayfa.Content{title: "Note", body: "<p>B</p>", date: ~D[2024-01-10], slug: "note", meta: %{"content_type" => "notes", "url_prefix" => "notes"}}
      ...> ]
      iex> config = %{title: "My Site", base_url: "https://example.com", author: "Author"}
      iex> xml = Sayfa.Feed.generate_for_type(contents, "posts", config)
      iex> xml =~ "Post"
      true
      iex> xml =~ "Note"
      false

  """
  @spec generate_for_type([Content.t()], String.t(), map()) :: String.t()
  def generate_for_type(contents, type_name, config) do
    contents
    |> Content.all_of_type(type_name)
    |> Enum.filter(& &1.date)
    |> Content.sort_by_date(:desc)
    |> build_feed(config, "/feed/#{type_name}.xml")
  end

  defp build_feed(contents, config, feed_path) do
    base_url = String.trim_trailing(config.base_url, "/")
    updated = latest_date(contents)

    feed_element =
      XmlBuilder.element(:feed, %{xmlns: "http://www.w3.org/2005/Atom"}, [
        XmlBuilder.element(:title, config.title),
        XmlBuilder.element(:link, %{href: "#{base_url}#{feed_path}", rel: "self"}),
        XmlBuilder.element(:link, %{href: base_url}),
        XmlBuilder.element(:id, base_url),
        XmlBuilder.element(:updated, to_rfc3339(updated))
        | author_element(config) ++ Enum.map(contents, &entry_element(&1, config))
      ])

    XmlBuilder.generate(feed_element, format: :none)
    |> prepend_xml_declaration()
  end

  defp entry_element(%Content{} = content, config) do
    url = Sayfa.SEO.content_url(content, config)
    description = content.meta["description"]
    summary = if description, do: description, else: truncate_text(content.body, 300)

    XmlBuilder.element(:entry, [
      XmlBuilder.element(:title, content.title),
      XmlBuilder.element(:link, %{href: url}),
      XmlBuilder.element(:id, url),
      XmlBuilder.element(:updated, to_rfc3339(content.date)),
      XmlBuilder.element(:summary, summary),
      XmlBuilder.element(:content, %{type: "html"}, content.body)
    ])
  end

  defp author_element(%{author: author}) when is_binary(author) and author != "" do
    [XmlBuilder.element(:author, [XmlBuilder.element(:name, author)])]
  end

  defp author_element(_config), do: []

  defp latest_date([]), do: Date.utc_today()
  defp latest_date([first | _]), do: first.date

  @doc false
  @spec to_rfc3339(Date.t() | nil) :: String.t()
  def to_rfc3339(nil), do: to_rfc3339(Date.utc_today())
  def to_rfc3339(%Date{} = date), do: "#{Date.to_iso8601(date)}T00:00:00Z"

  defp truncate_text(html, max_length) do
    html
    |> then(&Regex.replace(~r/<[^>]*>/, &1, ""))
    |> then(&Regex.replace(~r/\s+/, &1, " "))
    |> String.trim()
    |> String.slice(0, max_length)
  end

  defp prepend_xml_declaration(xml) do
    ~s(<?xml version="1.0" encoding="utf-8"?>) <> xml
  end
end
