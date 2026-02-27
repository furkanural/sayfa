defmodule Sayfa.FeedTest do
  use ExUnit.Case, async: true
  doctest Sayfa.Feed

  alias Sayfa.Content
  alias Sayfa.Feed

  @config %{title: "My Site", base_url: "https://example.com", author: "Test Author"}

  defp make_content(attrs) do
    defaults = %{
      body: "<p>Body</p>",
      tags: [],
      categories: [],
      draft: false,
      meta: %{"url_prefix" => "posts"}
    }

    struct!(Content, Map.merge(defaults, attrs))
  end

  describe "generate/2" do
    test "generates valid Atom XML" do
      contents = [
        make_content(%{title: "First Post", date: ~D[2024-01-15], slug: "first-post"}),
        make_content(%{title: "Second Post", date: ~D[2024-01-20], slug: "second-post"})
      ]

      xml = Feed.generate(contents, @config)

      assert xml =~ ~s(<?xml version="1.0" encoding="utf-8"?>)
      assert xml =~ ~s(<feed xmlns="http://www.w3.org/2005/Atom">)
      assert xml =~ "<title>My Site</title>"
      assert xml =~ "<author>"
      assert xml =~ "<name>Test Author</name>"
    end

    test "includes entries sorted by date desc" do
      contents = [
        make_content(%{title: "Older", date: ~D[2024-01-10], slug: "older"}),
        make_content(%{title: "Newer", date: ~D[2024-01-20], slug: "newer"})
      ]

      xml = Feed.generate(contents, @config)

      # Newer should appear before Older
      newer_pos = :binary.match(xml, "Newer") |> elem(0)
      older_pos = :binary.match(xml, "Older") |> elem(0)
      assert newer_pos < older_pos
    end

    test "excludes contents without dates" do
      contents = [
        make_content(%{title: "Dated", date: ~D[2024-01-15], slug: "dated"}),
        make_content(%{title: "Undated", date: nil, slug: "undated"})
      ]

      xml = Feed.generate(contents, @config)

      assert xml =~ "Dated"
      refute xml =~ "Undated"
    end

    test "includes feed self link" do
      xml = Feed.generate([], @config)
      assert xml =~ ~s(href="https://example.com/feed.xml")
    end

    test "includes entry URLs" do
      contents = [make_content(%{title: "Post", date: ~D[2024-01-15], slug: "post"})]
      xml = Feed.generate(contents, @config)
      assert xml =~ "https://example.com/posts/post"
    end

    test "includes entry content" do
      contents = [
        make_content(%{
          title: "Post",
          date: ~D[2024-01-15],
          slug: "post",
          body: "<p>Hello world</p>"
        })
      ]

      xml = Feed.generate(contents, @config)
      assert xml =~ "Hello world"
    end

    test "omits author element when author is nil" do
      config = Map.put(@config, :author, nil)
      xml = Feed.generate([], config)
      refute xml =~ "<author>"
    end
  end

  describe "generate_for_type/3" do
    test "filters by content type" do
      contents = [
        make_content(%{
          title: "Post",
          date: ~D[2024-01-15],
          slug: "post",
          meta: %{"content_type" => "posts", "url_prefix" => "posts"}
        }),
        make_content(%{
          title: "Note",
          date: ~D[2024-01-10],
          slug: "note",
          meta: %{"content_type" => "notes", "url_prefix" => "notes"}
        })
      ]

      xml = Feed.generate_for_type(contents, "posts", @config)

      assert xml =~ "Post"
      refute xml =~ "Note"
    end

    test "uses type-specific feed path" do
      xml = Feed.generate_for_type([], "posts", @config)
      assert xml =~ ~s(href="https://example.com/feed/posts.xml")
    end
  end

  describe "to_rfc3339/1" do
    test "formats date" do
      assert Feed.to_rfc3339(~D[2024-01-15]) == "2024-01-15T00:00:00Z"
    end
  end

  describe "generate_for_tag/3" do
    test "filters content by tag" do
      contents = [
        make_content(%{
          title: "Elixir Post",
          date: ~D[2024-01-15],
          slug: "elixir-post",
          tags: ["elixir"]
        }),
        make_content(%{
          title: "Other Post",
          date: ~D[2024-01-10],
          slug: "other-post",
          tags: ["ruby"]
        })
      ]

      xml = Feed.generate_for_tag(contents, "elixir", @config)

      assert xml =~ "Elixir Post"
      refute xml =~ "Other Post"
    end

    test "uses tag-specific feed path" do
      xml = Feed.generate_for_tag([], "elixir", @config)
      assert xml =~ ~s(href="https://example.com/feed/tags/elixir.xml")
    end

    test "slugifies tag in feed path" do
      xml = Feed.generate_for_tag([], "Elixir Tips", @config)
      assert xml =~ ~s(/feed/tags/elixir-tips.xml)
    end

    test "excludes undated content" do
      contents = [
        make_content(%{title: "Dated", date: ~D[2024-01-15], slug: "dated", tags: ["elixir"]}),
        make_content(%{title: "Undated", date: nil, slug: "undated", tags: ["elixir"]})
      ]

      xml = Feed.generate_for_tag(contents, "elixir", @config)

      assert xml =~ "Dated"
      refute xml =~ "Undated"
    end

    test "returns empty feed when no content has tag" do
      contents = [
        make_content(%{title: "Post", date: ~D[2024-01-15], slug: "post", tags: ["ruby"]})
      ]

      xml = Feed.generate_for_tag(contents, "elixir", @config)

      refute xml =~ "Post"
      assert xml =~ "<feed"
    end
  end

  describe "generate_for_category/3" do
    test "filters content by category" do
      contents = [
        make_content(%{
          title: "News Item",
          date: ~D[2024-01-15],
          slug: "news-item",
          categories: ["news"]
        }),
        make_content(%{
          title: "Tutorial",
          date: ~D[2024-01-10],
          slug: "tutorial",
          categories: ["tutorials"]
        })
      ]

      xml = Feed.generate_for_category(contents, "news", @config)

      assert xml =~ "News Item"
      refute xml =~ "Tutorial"
    end

    test "uses category-specific feed path" do
      xml = Feed.generate_for_category([], "news", @config)
      assert xml =~ ~s(href="https://example.com/feed/categories/news.xml")
    end

    test "slugifies category in feed path" do
      xml = Feed.generate_for_category([], "Open Source", @config)
      assert xml =~ ~s(/feed/categories/open-source.xml)
    end
  end

  describe "generate_json/2" do
    test "returns valid JSON with required fields" do
      contents = [
        make_content(%{title: "Hello", date: ~D[2024-01-15], slug: "hello"})
      ]

      json = Feed.generate_json(contents, @config)
      decoded = JSON.decode!(json)

      assert decoded["version"] == "https://jsonfeed.org/version/1.1"
      assert decoded["title"] == "My Site"
      assert decoded["feed_url"] == "https://example.com/feed.json"
      assert decoded["home_page_url"] == "https://example.com/"
    end

    test "includes items sorted by date desc" do
      contents = [
        make_content(%{title: "Older", date: ~D[2024-01-10], slug: "older"}),
        make_content(%{title: "Newer", date: ~D[2024-01-20], slug: "newer"})
      ]

      json = Feed.generate_json(contents, @config)
      decoded = JSON.decode!(json)
      titles = Enum.map(decoded["items"], & &1["title"])

      assert titles == ["Newer", "Older"]
    end

    test "excludes undated content" do
      contents = [
        make_content(%{title: "Dated", date: ~D[2024-01-15], slug: "dated"}),
        make_content(%{title: "Undated", date: nil, slug: "undated"})
      ]

      json = Feed.generate_json(contents, @config)
      decoded = JSON.decode!(json)
      titles = Enum.map(decoded["items"], & &1["title"])

      assert "Dated" in titles
      refute "Undated" in titles
    end

    test "includes author when configured" do
      json = Feed.generate_json([], @config)
      decoded = JSON.decode!(json)

      assert [%{"name" => "Test Author"}] = decoded["authors"]
    end

    test "omits authors when author is nil" do
      config = Map.put(@config, :author, nil)
      json = Feed.generate_json([], config)
      decoded = JSON.decode!(json)

      refute Map.has_key?(decoded, "authors")
    end

    test "includes content_html and summary in items" do
      contents = [
        make_content(%{
          title: "Post",
          date: ~D[2024-01-15],
          slug: "post",
          body: "<p>Hello world</p>"
        })
      ]

      json = Feed.generate_json(contents, @config)
      decoded = JSON.decode!(json)
      [item] = decoded["items"]

      assert item["content_html"] == "<p>Hello world</p>"
      assert is_binary(item["summary"])
    end

    test "includes tags when present" do
      contents = [
        make_content(%{
          title: "Tagged",
          date: ~D[2024-01-15],
          slug: "tagged",
          tags: ["elixir", "otp"]
        })
      ]

      json = Feed.generate_json(contents, @config)
      decoded = JSON.decode!(json)
      [item] = decoded["items"]

      assert item["tags"] == ["elixir", "otp"]
    end
  end

  describe "generate_json_for_type/3" do
    test "filters by content type" do
      contents = [
        make_content(%{
          title: "Post",
          date: ~D[2024-01-15],
          slug: "post",
          meta: %{"content_type" => "posts", "url_prefix" => "posts"}
        }),
        make_content(%{
          title: "Note",
          date: ~D[2024-01-10],
          slug: "note",
          meta: %{"content_type" => "notes", "url_prefix" => "notes"}
        })
      ]

      json = Feed.generate_json_for_type(contents, "posts", @config)
      decoded = JSON.decode!(json)
      titles = Enum.map(decoded["items"], & &1["title"])

      assert "Post" in titles
      refute "Note" in titles
    end

    test "uses type-specific feed url" do
      json = Feed.generate_json_for_type([], "posts", @config)
      decoded = JSON.decode!(json)

      assert decoded["feed_url"] == "https://example.com/feed/posts.json"
    end
  end
end
