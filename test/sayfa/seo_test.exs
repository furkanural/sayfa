defmodule Sayfa.SEOTest do
  use ExUnit.Case, async: true
  doctest Sayfa.SEO

  alias Sayfa.SEO
  alias Sayfa.Content

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
      assert html =~ ~s(property="og:url" content="https://example.com/posts/hello-world/")
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
      assert html =~ ~s(rel="canonical" href="https://example.com/posts/hello/")
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

  describe "content_url/2" do
    test "builds URL with prefix" do
      content = %Content{title: "T", body: "", slug: "hello", meta: %{"url_prefix" => "posts"}}
      assert SEO.content_url(content, @config) == "https://example.com/posts/hello/"
    end

    test "builds URL without prefix" do
      content = %Content{title: "T", body: "", slug: "about", meta: %{"url_prefix" => ""}}
      assert SEO.content_url(content, @config) == "https://example.com/about/"
    end

    test "handles trailing slash in base_url" do
      content = %Content{title: "T", body: "", slug: "hello", meta: %{"url_prefix" => "posts"}}
      config = %{base_url: "https://example.com/"}
      assert SEO.content_url(content, config) == "https://example.com/posts/hello/"
    end
  end
end
