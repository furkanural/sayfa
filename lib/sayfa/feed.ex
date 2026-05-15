defmodule Sayfa.Feed do
  @moduledoc """
  Generates Atom feeds from content.

  Produces standard Atom XML feeds for syndication. Generates a main feed
  for all dated content and per-type feeds for specific content types.

  ## Examples

      contents = [%Sayfa.Content{title: "Hello", body: "<p>World</p>", date: ~D[2024-01-15], slug: "hello", meta: %{"url_prefix" => "articles"}}]
      config = %{title: "My Site", base_url: "https://example.com", author: "Author"}
      xml = Sayfa.Feed.generate(contents, config)

  """

  alias Sayfa.Content
  alias Slug

  @type filter :: :all | {:type, String.t()} | {:tag, String.t()} | {:category, String.t()}
  @type format :: :atom | :json

  @doc """
  Generates a feed for the given filter and format.

  This is the core function that powers all feed generation. The convenience
  wrappers below delegate to it.

  ## Examples

      iex> contents = [%Sayfa.Content{title: "Hello", body: "<p>World</p>", date: ~D[2024-01-15], slug: "hello", meta: %{"url_prefix" => "articles"}}]
      iex> config = %{title: "My Site", base_url: "https://example.com", author: "Author"}
      iex> xml = Sayfa.Feed.generate(contents, config)
      iex> xml =~ "<feed"
      true

      iex> contents = [%Sayfa.Content{title: "Hello", body: "<p>World</p>", date: ~D[2024-01-15], slug: "hello", meta: %{"url_prefix" => "articles"}}]
      iex> config = %{title: "My Site", base_url: "https://example.com", author: "Author"}
      iex> xml = Sayfa.Feed.generate(contents, config, :all, :atom)
      iex> xml =~ "<feed"
      true

  """
  @spec generate([Content.t()], map(), filter(), format()) :: String.t()
  def generate(contents, config, filter \\ :all, format \\ :atom) do
    contents
    |> apply_filter(filter)
    |> Enum.filter(& &1.date)
    |> Content.sort_by_date(:desc)
    |> build(format, config, feed_path(filter, format))
  end

  @doc """
  Generates an Atom XML feed for a specific content type.

  ## Examples

      iex> contents = [
      ...>   %Sayfa.Content{title: "Article", body: "<p>A</p>", date: ~D[2024-01-15], slug: "Article", meta: %{"content_type" => "articles", "url_prefix" => "articles"}},
      ...>   %Sayfa.Content{title: "Note", body: "<p>B</p>", date: ~D[2024-01-10], slug: "note", meta: %{"content_type" => "notes", "url_prefix" => "notes"}}
      ...> ]
      iex> config = %{title: "My Site", base_url: "https://example.com", author: "Author"}
      iex> xml = Sayfa.Feed.generate_for_type(contents, "articles", config)
      iex> xml =~ "Article"
      true
      iex> xml =~ "Note"
      false

  """
  @spec generate_for_type([Content.t()], String.t(), map()) :: String.t()
  def generate_for_type(contents, type_name, config),
    do: generate(contents, config, {:type, type_name}, :atom)

  @doc """
  Generates a JSON Feed 1.1 string for all dated content.

  ## Examples

      iex> contents = [%Sayfa.Content{title: "Hello", body: "<p>World</p>", date: ~D[2024-01-15], slug: "hello", meta: %{"url_prefix" => "articles"}}]
      iex> config = %{title: "My Site", base_url: "https://example.com", author: "Author"}
      iex> json = Sayfa.Feed.generate_json(contents, config)
      iex> json =~ "jsonfeed.org"
      true

  """
  @spec generate_json([Content.t()], map()) :: String.t()
  def generate_json(contents, config), do: generate(contents, config, :all, :json)

  @doc """
  Generates a JSON Feed 1.1 string for a specific content type.

  ## Examples

      iex> contents = [
      ...>   %Sayfa.Content{title: "Article", body: "<p>A</p>", date: ~D[2024-01-15], slug: "Article", meta: %{"content_type" => "articles", "url_prefix" => "articles"}},
      ...>   %Sayfa.Content{title: "Note", body: "<p>B</p>", date: ~D[2024-01-10], slug: "note", meta: %{"content_type" => "notes", "url_prefix" => "notes"}}
      ...> ]
      iex> config = %{title: "My Site", base_url: "https://example.com", author: "Author"}
      iex> json = Sayfa.Feed.generate_json_for_type(contents, "articles", config)
      iex> json =~ "Article"
      true
      iex> json =~ "Note"
      false

  """
  @spec generate_json_for_type([Content.t()], String.t(), map()) :: String.t()
  def generate_json_for_type(contents, type_name, config),
    do: generate(contents, config, {:type, type_name}, :json)

  @doc """
  Generates an Atom XML feed for a specific tag.

  ## Examples

      iex> contents = [%Sayfa.Content{title: "Tagged", body: "<p>A</p>", date: ~D[2024-01-15], slug: "tagged", tags: ["elixir"], meta: %{"url_prefix" => "articles"}}]
      iex> config = %{title: "My Site", base_url: "https://example.com", author: "Author"}
      iex> xml = Sayfa.Feed.generate_for_tag(contents, "elixir", config)
      iex> xml =~ "Tagged"
      true

  """
  @spec generate_for_tag([Content.t()], String.t(), map()) :: String.t()
  def generate_for_tag(contents, tag, config),
    do: generate(contents, config, {:tag, tag}, :atom)

  @doc """
  Generates an Atom XML feed for a specific category.

  ## Examples

      iex> contents = [%Sayfa.Content{title: "Categorized", body: "<p>A</p>", date: ~D[2024-01-15], slug: "categorized", categories: ["news"], meta: %{"url_prefix" => "articles"}}]
      iex> config = %{title: "My Site", base_url: "https://example.com", author: "Author"}
      iex> xml = Sayfa.Feed.generate_for_category(contents, "news", config)
      iex> xml =~ "Categorized"
      true

  """
  @spec generate_for_category([Content.t()], String.t(), map()) :: String.t()
  def generate_for_category(contents, category, config),
    do: generate(contents, config, {:category, category}, :atom)

  @doc """
  Generates a JSON Feed 1.1 string for a specific tag.

  ## Examples

      iex> contents = [%Sayfa.Content{title: "Tagged", body: "<p>A</p>", date: ~D[2024-01-15], slug: "tagged", tags: ["elixir"], meta: %{"url_prefix" => "articles"}}]
      iex> config = %{title: "My Site", base_url: "https://example.com", author: "Author"}
      iex> json = Sayfa.Feed.generate_json_for_tag(contents, "elixir", config)
      iex> json =~ "Tagged"
      true

  """
  @spec generate_json_for_tag([Content.t()], String.t(), map()) :: String.t()
  def generate_json_for_tag(contents, tag, config),
    do: generate(contents, config, {:tag, tag}, :json)

  @doc """
  Generates a JSON Feed 1.1 string for a specific category.

  ## Examples

      iex> contents = [%Sayfa.Content{title: "Categorized", body: "<p>A</p>", date: ~D[2024-01-15], slug: "categorized", categories: ["news"], meta: %{"url_prefix" => "articles"}}]
      iex> config = %{title: "My Site", base_url: "https://example.com", author: "Author"}
      iex> json = Sayfa.Feed.generate_json_for_category(contents, "news", config)
      iex> json =~ "Categorized"
      true

  """
  @spec generate_json_for_category([Content.t()], String.t(), map()) :: String.t()
  def generate_json_for_category(contents, category, config),
    do: generate(contents, config, {:category, category}, :json)

  # --- Internal helpers ---

  defp apply_filter(contents, :all), do: contents
  defp apply_filter(contents, {:type, type}), do: Content.all_of_type(contents, type)
  defp apply_filter(contents, {:tag, tag}), do: Content.with_tag(contents, tag)

  defp apply_filter(contents, {:category, category}),
    do: Content.with_category(contents, category)

  defp feed_path(:all, :atom), do: "/feed.xml"
  defp feed_path(:all, :json), do: "/feed.json"
  defp feed_path({:type, type}, :atom), do: "/feed/#{type}.xml"
  defp feed_path({:type, type}, :json), do: "/feed/#{type}.json"
  defp feed_path({:tag, tag}, :atom), do: "/feed/tags/#{Slug.slugify(tag)}.xml"
  defp feed_path({:tag, tag}, :json), do: "/feed/tags/#{Slug.slugify(tag)}.json"
  defp feed_path({:category, cat}, :atom), do: "/feed/categories/#{Slug.slugify(cat)}.xml"
  defp feed_path({:category, cat}, :json), do: "/feed/categories/#{Slug.slugify(cat)}.json"

  defp build(contents, :atom, config, path), do: build_feed(contents, config, path)
  defp build(contents, :json, config, path), do: build_json_feed(contents, config, path)

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

    summary =
      if description,
        do: description,
        else: truncate_text(content.body, Sayfa.Config.get(:feed_summary_length, 300))

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

  defp build_json_feed(contents, config, feed_url_path) do
    base_url = String.trim_trailing(config.base_url, "/")
    author = Map.get(config, :author)

    feed =
      %{
        "version" => "https://jsonfeed.org/version/1.1",
        "title" => config.title,
        "home_page_url" => base_url <> "/",
        "feed_url" => base_url <> feed_url_path,
        "items" => Enum.map(contents, &json_item(&1, config))
      }

    feed =
      if is_binary(author) and author != "" do
        Map.put(feed, "authors", [%{"name" => author}])
      else
        feed
      end

    JSON.encode!(feed)
  end

  defp json_item(%Content{} = content, config) do
    url = Sayfa.SEO.content_url(content, config)
    description = content.meta["description"]

    summary =
      if description,
        do: description,
        else: truncate_text(content.body, Sayfa.Config.get(:feed_summary_length, 300))

    item = %{
      "id" => url,
      "url" => url,
      "title" => content.title,
      "summary" => summary,
      "content_html" => content.body,
      "date_published" => to_rfc3339(content.date)
    }

    if content.tags != [] do
      Map.put(item, "tags", content.tags)
    else
      item
    end
  end
end
