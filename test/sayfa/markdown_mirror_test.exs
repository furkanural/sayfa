defmodule Sayfa.MarkdownMirrorTest do
  use ExUnit.Case, async: true
  doctest Sayfa.MarkdownMirror

  alias Sayfa.Content
  alias Sayfa.MarkdownMirror

  defp make_content(opts \\ []) do
    meta =
      Map.merge(
        %{"url_prefix" => "articles", "lang_prefix" => "", "body_markdown" => "Body *markdown*."},
        Keyword.get(opts, :meta, %{})
      )

    struct!(
      Content,
      [title: "Hello", body: "<p>Hi</p>", slug: "hello", meta: meta]
      |> Keyword.merge(Keyword.delete(opts, :meta))
    )
  end

  describe "render/2" do
    test "includes title and original markdown body" do
      md = MarkdownMirror.render(make_content(), %{})

      assert md =~ "# Hello"
      assert md =~ "Body *markdown*."
      assert String.ends_with?(md, "\n")
    end

    test "omits metadata line parts that are unavailable" do
      md = MarkdownMirror.render(make_content(), %{})

      refute md =~ "Published"
      refute md =~ "Tags:"
    end

    test "includes canonical URL when base_url is configured" do
      md = MarkdownMirror.render(make_content(), %{base_url: "https://example.com"})

      assert md =~ "https://example.com/articles/hello"
    end

    test "renders without metadata line when body_markdown is missing" do
      content = make_content(meta: %{"body_markdown" => nil})
      md = MarkdownMirror.render(content, %{})

      assert md == "# Hello\n\n\n"
    end
  end

  describe "path/2" do
    test "places mirror next to the article directory" do
      assert MarkdownMirror.path(make_content(), "output/articles/hello/index.html") ==
               "output/articles/hello.md"
    end

    test "places mirror next to page directories" do
      assert MarkdownMirror.path(make_content(slug: "about"), "output/about/index.html") ==
               "output/about.md"
    end

    test "preserves language prefixes" do
      assert MarkdownMirror.path(
               make_content(slug: "merhaba"),
               "output/tr/articles/merhaba/index.html"
             ) ==
               "output/tr/articles/merhaba.md"
    end
  end

  describe "url/1" do
    test "appends .md to the content URL" do
      assert MarkdownMirror.url(make_content()) == "/articles/hello.md"
    end

    test "includes language prefix" do
      content = make_content(slug: "merhaba", meta: %{"lang_prefix" => "tr"})

      assert MarkdownMirror.url(content) == "/tr/articles/merhaba.md"
    end
  end

  describe "enabled?/1" do
    test "defaults to true" do
      assert MarkdownMirror.enabled?(%{})
    end

    test "can be disabled" do
      refute MarkdownMirror.enabled?(%{markdown_mirrors: false})
    end
  end
end
