defmodule Sayfa.SEOTest do
  use ExUnit.Case, async: true
  doctest Sayfa.SEO

  alias Sayfa.Content
  alias Sayfa.SEO

  @config %{title: "My Site", base_url: "https://example.com", description: "A great blog"}

  describe "meta_tags/2 with content" do
    test "generates Open Graph tags" do
      content = %Content{
        title: "Hello World",
        body: "<p>Post body text</p>",
        slug: "hello-world",
        meta: %{"url_prefix" => "posts"}
      }

      html = SEO.meta_tags(content, @config)
      assert html =~ ~s(property="og:title" content="Hello World")
      assert html =~ ~s(property="og:type" content="article")
      assert html =~ ~s(property="og:url" content="https://example.com/posts/hello-world")
      assert html =~ ~s(property="og:site_name" content="My Site")
    end

    test "generates Twitter Card tags" do
      content = %Content{
        title: "Hello",
        body: "<p>Body</p>",
        slug: "hello",
        meta: %{"url_prefix" => "posts"}
      }

      html = SEO.meta_tags(content, @config)
      assert html =~ ~s(property="twitter:card" content="summary")
      assert html =~ ~s(property="twitter:title" content="Hello")
    end

    test "uses description from meta" do
      content = %Content{
        title: "Hello",
        body: "<p>Long body text</p>",
        slug: "hello",
        meta: %{"url_prefix" => "posts", "description" => "Custom SEO description"}
      }

      html = SEO.meta_tags(content, @config)
      assert html =~ ~s(name="description" content="Custom SEO description")
    end

    test "falls back to truncated body text" do
      content = %Content{
        title: "Hello",
        body: "<p>This is the body text that will be used as description</p>",
        slug: "hello",
        meta: %{"url_prefix" => "posts"}
      }

      html = SEO.meta_tags(content, @config)
      assert html =~ ~s(name="description" content="This is the body text)
    end

    test "generates canonical URL" do
      content = %Content{
        title: "Hello",
        body: "<p>Body</p>",
        slug: "hello",
        meta: %{"url_prefix" => "posts"}
      }

      html = SEO.meta_tags(content, @config)
      assert html =~ ~s(rel="canonical" href="https://example.com/posts/hello")
    end

    test "includes image tags when image is in meta" do
      content = %Content{
        title: "Hello",
        body: "<p>Body</p>",
        slug: "hello",
        meta: %{"url_prefix" => "posts", "image" => "/images/cover.jpg"}
      }

      html = SEO.meta_tags(content, @config)
      assert html =~ ~s(property="og:image" content="/images/cover.jpg")
      assert html =~ ~s(property="twitter:image" content="/images/cover.jpg")
    end

    test "escapes special characters in attributes" do
      content = %Content{
        title: ~s(Hello "World" & <Friends>),
        body: "<p>Body</p>",
        slug: "hello",
        meta: %{"url_prefix" => "posts"}
      }

      html = SEO.meta_tags(content, @config)
      assert html =~ "&amp;"
      assert html =~ "&quot;"
      assert html =~ "&lt;"
    end
  end

  describe "meta_tags/2 with nil content" do
    test "uses site-level defaults" do
      html = SEO.meta_tags(nil, @config)
      assert html =~ ~s(property="og:title" content="My Site")
      assert html =~ ~s(name="description" content="A great blog")
      assert html =~ ~s(property="og:type" content="website")
    end
  end

  describe "meta_tags/2 article OG tags" do
    test "adds article:published_time for posts" do
      content = %Content{
        title: "Hello",
        body: "<p>Body</p>",
        slug: "hello",
        date: ~D[2024-01-15],
        meta: %{"url_prefix" => "posts", "content_type" => "posts"}
      }

      html = SEO.meta_tags(content, @config)
      assert html =~ ~s(property="article:published_time" content="2024-01-15")
    end

    test "adds article:modified_time when updated is present" do
      content = %Content{
        title: "Hello",
        body: "<p>Body</p>",
        slug: "hello",
        date: ~D[2024-01-15],
        meta: %{
          "url_prefix" => "posts",
          "content_type" => "posts",
          "updated" => ~D[2024-02-01]
        }
      }

      html = SEO.meta_tags(content, @config)
      assert html =~ ~s(property="article:modified_time" content="2024-02-01")
    end

    test "adds article:author from config" do
      content = %Content{
        title: "Hello",
        body: "<p>Body</p>",
        slug: "hello",
        meta: %{"url_prefix" => "posts", "content_type" => "posts"}
      }

      config = Map.put(@config, :author, "Jane Doe")
      html = SEO.meta_tags(content, config)
      assert html =~ ~s(property="article:author" content="Jane Doe")
    end

    test "adds article:tag for each tag" do
      content = %Content{
        title: "Hello",
        body: "<p>Body</p>",
        slug: "hello",
        tags: ["elixir", "phoenix"],
        meta: %{"url_prefix" => "posts", "content_type" => "posts"}
      }

      html = SEO.meta_tags(content, @config)
      assert html =~ ~s(property="article:tag" content="elixir")
      assert html =~ ~s(property="article:tag" content="phoenix")
    end

    test "does not add article tags for pages" do
      content = %Content{
        title: "About",
        body: "<p>Body</p>",
        slug: "about",
        date: ~D[2024-01-15],
        meta: %{"url_prefix" => "", "content_type" => "pages"}
      }

      html = SEO.meta_tags(content, @config)
      refute html =~ "article:published_time"
    end

    test "adds article tags for notes" do
      content = %Content{
        title: "A Note",
        body: "<p>Body</p>",
        slug: "note",
        date: ~D[2024-01-15],
        meta: %{"url_prefix" => "notes", "content_type" => "notes"}
      }

      html = SEO.meta_tags(content, @config)
      assert html =~ ~s(property="article:published_time" content="2024-01-15")
    end
  end

  describe "meta_tags/2 dynamic twitter:card" do
    test "uses summary by default" do
      content = %Content{
        title: "Hello",
        body: "<p>Body</p>",
        slug: "hello",
        meta: %{"url_prefix" => "posts"}
      }

      html = SEO.meta_tags(content, @config)
      assert html =~ ~s(property="twitter:card" content="summary")
    end

    test "uses summary_large_image when image is present" do
      content = %Content{
        title: "Hello",
        body: "<p>Body</p>",
        slug: "hello",
        meta: %{"url_prefix" => "posts", "image" => "/images/cover.jpg"}
      }

      html = SEO.meta_tags(content, @config)
      assert html =~ ~s(property="twitter:card" content="summary_large_image")
    end
  end

  describe "json_ld/2" do
    test "generates BlogPosting for posts" do
      content = %Content{
        title: "Hello World",
        body: "<p>Body text</p>",
        slug: "hello",
        date: ~D[2024-01-15],
        tags: ["elixir"],
        meta: %{
          "content_type" => "posts",
          "url_prefix" => "posts",
          "lang_prefix" => ""
        }
      }

      config = Map.put(@config, :author, "Jane")
      html = SEO.json_ld(content, config)

      assert html =~ ~s(application/ld+json)
      assert html =~ ~s("BlogPosting")
      assert html =~ ~s("Hello World")
      assert html =~ ~s("2024-01-15")
      assert html =~ ~s("Jane")
      assert html =~ ~s("elixir")
    end

    test "generates WebPage for pages" do
      content = %Content{
        title: "About",
        body: "<p>About me</p>",
        slug: "about",
        meta: %{
          "content_type" => "pages",
          "url_prefix" => "",
          "lang_prefix" => ""
        }
      }

      html = SEO.json_ld(content, @config)
      assert html =~ ~s("WebPage")
      assert html =~ ~s("About")
    end

    test "generates WebSite for nil content" do
      html = SEO.json_ld(nil, @config)
      assert html =~ ~s("WebSite")
      assert html =~ ~s("My Site")
    end

    test "includes dateModified when updated is present" do
      content = %Content{
        title: "Hello",
        body: "<p>Body</p>",
        slug: "hello",
        date: ~D[2024-01-15],
        meta: %{
          "content_type" => "posts",
          "url_prefix" => "posts",
          "lang_prefix" => "",
          "updated" => ~D[2024-02-01]
        }
      }

      html = SEO.json_ld(content, @config)
      assert html =~ ~s("2024-02-01")
    end
  end

  describe "hreflang_tags/2" do
    test "renders hreflang links from alternates" do
      content = %Content{
        title: "Hello",
        body: "",
        slug: "hello",
        meta: %{
          "url_prefix" => "posts",
          "lang_prefix" => "",
          "hreflang_alternates" => [
            {"en", "/posts/hello"},
            {"tr", "/tr/posts/merhaba"}
          ]
        }
      }

      html = SEO.hreflang_tags(content, @config)
      assert html =~ ~s(hreflang="en")
      assert html =~ ~s(hreflang="tr")
      assert html =~ ~s(href="https://example.com/posts/hello")
      assert html =~ ~s(href="https://example.com/tr/posts/merhaba")
    end

    test "adds x-default when multiple alternates exist" do
      content = %Content{
        title: "Hello",
        body: "",
        slug: "hello",
        meta: %{
          "url_prefix" => "posts",
          "lang_prefix" => "",
          "hreflang_alternates" => [
            {"en", "/posts/hello"},
            {"tr", "/tr/posts/merhaba"}
          ]
        }
      }

      html = SEO.hreflang_tags(content, @config)
      assert html =~ ~s(hreflang="x-default")
      # x-default points to the first (self) entry
      assert html =~ ~s(hreflang="x-default" href="https://example.com/posts/hello")
    end

    test "does not add x-default for single alternate" do
      content = %Content{
        title: "Hello",
        body: "",
        slug: "hello",
        meta: %{
          "url_prefix" => "posts",
          "lang_prefix" => "",
          "hreflang_alternates" => [{"en", "/posts/hello"}]
        }
      }

      html = SEO.hreflang_tags(content, @config)
      assert html =~ ~s(hreflang="en")
      refute html =~ "x-default"
    end

    test "returns empty string for nil content" do
      assert SEO.hreflang_tags(nil, @config) == ""
    end

    test "returns empty string when no alternates" do
      content = %Content{
        title: "Hello",
        body: "",
        slug: "hello",
        meta: %{"url_prefix" => "posts"}
      }

      assert SEO.hreflang_tags(content, @config) == ""
    end
  end

  describe "hreflang_tags/3 with archive_alternates" do
    test "renders hreflang links for list pages" do
      archive_alternates = %{en: "/posts/", tr: "/tr/posts/"}

      html = SEO.hreflang_tags(nil, @config, archive_alternates)
      assert html =~ ~s(hreflang="en")
      assert html =~ ~s(hreflang="tr")
      assert html =~ ~s(href="https://example.com/posts/")
      assert html =~ ~s(href="https://example.com/tr/posts/")
    end

    test "adds x-default pointing to default language for list pages" do
      config = Map.put(@config, :default_lang, :en)
      archive_alternates = %{en: "/posts/", tr: "/tr/posts/"}

      html = SEO.hreflang_tags(nil, config, archive_alternates)
      assert html =~ ~s(hreflang="x-default" href="https://example.com/posts/")
    end

    test "does not add x-default for single language" do
      archive_alternates = %{en: "/posts/"}

      html = SEO.hreflang_tags(nil, @config, archive_alternates)
      assert html =~ ~s(hreflang="en")
      refute html =~ "x-default"
    end

    test "returns empty string when archive_alternates is nil" do
      assert SEO.hreflang_tags(nil, @config, nil) == ""
    end

    test "returns empty string when archive_alternates is empty map" do
      assert SEO.hreflang_tags(nil, @config, %{}) == ""
    end

    test "content hreflang takes priority over archive_alternates" do
      content = %Content{
        title: "Hello",
        body: "",
        slug: "hello",
        meta: %{
          "url_prefix" => "posts",
          "lang_prefix" => "",
          "hreflang_alternates" => [
            {"en", "/posts/hello"},
            {"tr", "/tr/posts/merhaba"}
          ]
        }
      }

      archive_alternates = %{en: "/posts/", tr: "/tr/posts/"}

      html = SEO.hreflang_tags(content, @config, archive_alternates)
      # Should use content alternates, not archive alternates
      assert html =~ ~s(href="https://example.com/posts/hello")
      refute html =~ ~s(href="https://example.com/posts/")
    end
  end

  describe "content_url/2" do
    test "builds URL with prefix" do
      content = %Content{
        title: "T",
        body: "",
        slug: "hello",
        meta: %{"url_prefix" => "posts", "lang_prefix" => ""}
      }

      assert SEO.content_url(content, @config) == "https://example.com/posts/hello"
    end

    test "builds URL without prefix" do
      content = %Content{
        title: "T",
        body: "",
        slug: "about",
        meta: %{"url_prefix" => "", "lang_prefix" => ""}
      }

      assert SEO.content_url(content, @config) == "https://example.com/about"
    end

    test "handles trailing slash in base_url" do
      content = %Content{
        title: "T",
        body: "",
        slug: "hello",
        meta: %{"url_prefix" => "posts", "lang_prefix" => ""}
      }

      config = %{base_url: "https://example.com/"}
      assert SEO.content_url(content, config) == "https://example.com/posts/hello"
    end

    test "includes lang_prefix in URL" do
      content = %Content{
        title: "T",
        body: "",
        slug: "merhaba",
        meta: %{"url_prefix" => "posts", "lang_prefix" => "tr"}
      }

      assert SEO.content_url(content, @config) == "https://example.com/tr/posts/merhaba"
    end
  end
end
