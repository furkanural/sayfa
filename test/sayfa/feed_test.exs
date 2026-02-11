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
      assert xml =~ "https://example.com/posts/post/"
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
end
