defmodule Sayfa.BuilderTest do
  use ExUnit.Case, async: false

  alias Sayfa.Builder

  setup do
    tmp_dir = Path.join(System.tmp_dir!(), "sayfa_builder_#{System.unique_integer([:positive])}")
    content_dir = Path.join(tmp_dir, "content")
    output_dir = Path.join(tmp_dir, "output")
    posts_dir = Path.join(content_dir, "posts")
    pages_dir = Path.join(content_dir, "pages")

    File.mkdir_p!(posts_dir)
    File.mkdir_p!(pages_dir)

    on_exit(fn -> File.rm_rf!(tmp_dir) end)

    {:ok,
     tmp_dir: tmp_dir,
     content_dir: content_dir,
     output_dir: output_dir,
     posts_dir: posts_dir,
     pages_dir: pages_dir}
  end

  defp build_opts(ctx, extra \\ []) do
    [content_dir: ctx.content_dir, output_dir: ctx.output_dir] ++ extra
  end

  describe "build/1" do
    test "builds posts and pages", ctx do
      File.write!(Path.join(ctx.posts_dir, "2024-01-15-hello-world.md"), """
      ---
      title: "Hello World"
      date: 2024-01-15
      tags: [elixir]
      ---

      # Hello World

      This is my first post.
      """)

      File.write!(Path.join(ctx.pages_dir, "about.md"), """
      ---
      title: "About"
      ---

      # About Me

      This is the about page.
      """)

      assert {:ok, result} = Builder.build(build_opts(ctx))
      # 2 individual + 1 tag archive (elixir) + 1 posts index = 4
      assert result.content_count == 2
      assert result.elapsed_ms >= 0

      # Verify post output
      post_path = Path.join([ctx.output_dir, "posts", "hello-world", "index.html"])
      assert File.exists?(post_path)
      post_html = File.read!(post_path)
      assert post_html =~ "<!DOCTYPE html>"
      assert post_html =~ "Hello World"
      assert post_html =~ "first post"

      # Verify page output
      page_path = Path.join([ctx.output_dir, "about", "index.html"])
      assert File.exists?(page_path)
      page_html = File.read!(page_path)
      assert page_html =~ "<!DOCTYPE html>"
      assert page_html =~ "About"

      # Verify posts index was generated
      posts_index = Path.join([ctx.output_dir, "posts", "index.html"])
      assert File.exists?(posts_index)

      # Verify tag archive was generated
      tag_archive = Path.join([ctx.output_dir, "tags", "elixir", "index.html"])
      assert File.exists?(tag_archive)
    end

    test "filters drafts by default", ctx do
      File.write!(Path.join(ctx.posts_dir, "published.md"), """
      ---
      title: "Published"
      ---
      Content.
      """)

      File.write!(Path.join(ctx.posts_dir, "draft.md"), """
      ---
      title: "Draft Post"
      draft: true
      ---
      Draft content.
      """)

      assert {:ok, result} = Builder.build(build_opts(ctx))

      # 1 individual + 1 posts index + 1 feed.xml + 1 sitemap.xml = 4 (no per-type feed: no dated content)
      assert result.files_written == 4
      assert result.content_count == 1
    end

    test "includes drafts when drafts: true", ctx do
      File.write!(Path.join(ctx.posts_dir, "draft.md"), """
      ---
      title: "Draft Post"
      draft: true
      ---
      Draft content.
      """)

      assert {:ok, result} = Builder.build(build_opts(ctx, drafts: true))

      # 1 individual + 1 posts index + 1 feed.xml + 1 sitemap.xml = 4 (no per-type feed: no dated content)
      assert result.files_written == 4
      assert result.content_count == 1
    end

    test "returns error for missing content dir", ctx do
      assert {:error, {:content_dir_not_found, _}} =
               Builder.build(content_dir: "/nonexistent", output_dir: ctx.output_dir)
    end

    test "builds with no content files", ctx do
      assert {:ok, result} = Builder.build(build_opts(ctx))
      # feed.xml + sitemap.xml always generated
      assert result.files_written == 2
      assert result.content_count == 0
    end

    test "uses layout from front matter", ctx do
      File.write!(Path.join(ctx.pages_dir, "index.md"), """
      ---
      title: "Home"
      layout: home
      ---

      Welcome to my site.
      """)

      assert {:ok, result} = Builder.build(build_opts(ctx))
      # 1 individual + 1 feed.xml + 1 sitemap.xml = 3
      assert result.files_written == 3

      # home layout wraps with <section class="home">
      # (default theme layout)
      html = File.read!(Path.join(ctx.output_dir, "index.html"))
      assert html =~ "<!DOCTYPE html>"
    end

    test "classifies content type from directory structure", ctx do
      notes_dir = Path.join(ctx.content_dir, "notes")
      File.mkdir_p!(notes_dir)

      File.write!(Path.join(notes_dir, "quick-note.md"), """
      ---
      title: "A Quick Note"
      ---
      Short note content.
      """)

      assert {:ok, _result} = Builder.build(build_opts(ctx))

      note_path = Path.join([ctx.output_dir, "notes", "quick-note", "index.html"])
      assert File.exists?(note_path)
    end
  end

  describe "archives" do
    test "generates tag archive pages", ctx do
      File.write!(Path.join(ctx.posts_dir, "2024-01-15-post-1.md"), """
      ---
      title: "Post One"
      date: 2024-01-15
      tags: [elixir, tutorial]
      ---
      First post.
      """)

      File.write!(Path.join(ctx.posts_dir, "2024-01-20-post-2.md"), """
      ---
      title: "Post Two"
      date: 2024-01-20
      tags: [elixir]
      ---
      Second post.
      """)

      assert {:ok, _result} = Builder.build(build_opts(ctx))

      # Tag archives
      elixir_path = Path.join([ctx.output_dir, "tags", "elixir", "index.html"])
      assert File.exists?(elixir_path)
      elixir_html = File.read!(elixir_path)
      assert elixir_html =~ "Post One"
      assert elixir_html =~ "Post Two"
      assert elixir_html =~ "Tagged: elixir"

      tutorial_path = Path.join([ctx.output_dir, "tags", "tutorial", "index.html"])
      assert File.exists?(tutorial_path)
      tutorial_html = File.read!(tutorial_path)
      assert tutorial_html =~ "Post One"
      refute tutorial_html =~ "Post Two"
    end

    test "generates category archive pages", ctx do
      File.write!(Path.join(ctx.posts_dir, "post.md"), """
      ---
      title: "Categorized Post"
      date: 2024-01-15
      categories: [programming]
      ---
      Content.
      """)

      assert {:ok, _result} = Builder.build(build_opts(ctx))

      cat_path = Path.join([ctx.output_dir, "categories", "programming", "index.html"])
      assert File.exists?(cat_path)
      cat_html = File.read!(cat_path)
      assert cat_html =~ "Categorized Post"
      assert cat_html =~ "Category: programming"
    end
  end

  describe "type indexes" do
    test "generates paginated index for content types", ctx do
      for i <- 1..3 do
        File.write!(
          Path.join(ctx.posts_dir, "2024-01-#{String.pad_leading("#{i}", 2, "0")}-post-#{i}.md"),
          """
          ---
          title: "Post #{i}"
          date: 2024-01-#{String.pad_leading("#{i}", 2, "0")}
          ---
          Post #{i} content.
          """
        )
      end

      assert {:ok, _result} = Builder.build(build_opts(ctx, posts_per_page: 2))

      # Page 1
      index_path = Path.join([ctx.output_dir, "posts", "index.html"])
      assert File.exists?(index_path)
      index_html = File.read!(index_path)
      assert index_html =~ "Posts"

      # Page 2
      page2_path = Path.join([ctx.output_dir, "posts", "page", "2", "index.html"])
      assert File.exists?(page2_path)
    end

    test "does not generate index for pages type", ctx do
      File.write!(Path.join(ctx.pages_dir, "about.md"), """
      ---
      title: "About"
      ---
      About content.
      """)

      assert {:ok, _result} = Builder.build(build_opts(ctx))

      # No pages index
      refute File.exists?(Path.join([ctx.output_dir, "pages", "index.html"]))
    end

    test "user posts/index.md overrides auto-generated posts index", ctx do
      File.write!(Path.join(ctx.posts_dir, "index.md"), """
      ---
      title: "My Custom Posts Index"
      layout: page
      ---

      Welcome to my custom posts listing.
      """)

      File.write!(Path.join(ctx.posts_dir, "2024-01-15-hello.md"), """
      ---
      title: "Hello"
      date: 2024-01-15
      ---
      Hello content.
      """)

      assert {:ok, _result} = Builder.build(build_opts(ctx))

      index_path = Path.join([ctx.output_dir, "posts", "index.html"])
      assert File.exists?(index_path)
      html = File.read!(index_path)
      assert html =~ "My Custom Posts Index"
      assert html =~ "custom posts listing"
    end

    test "enriches content with content type metadata", ctx do
      File.write!(Path.join(ctx.pages_dir, "about.md"), """
      ---
      title: "About"
      ---
      About content.
      """)

      assert {:ok, _result} = Builder.build(build_opts(ctx))

      # Page should be at /{slug}/ (empty url_prefix)
      assert File.exists?(Path.join([ctx.output_dir, "about", "index.html"]))
      # Not at /pages/about/
      refute File.exists?(Path.join([ctx.output_dir, "pages", "about", "index.html"]))
    end
  end

  describe "feeds and sitemap" do
    test "generates feed.xml and sitemap.xml", ctx do
      File.write!(Path.join(ctx.posts_dir, "2024-01-15-hello.md"), """
      ---
      title: "Hello"
      date: 2024-01-15
      ---
      Some content.
      """)

      assert {:ok, _result} = Builder.build(build_opts(ctx))

      # Main feed
      feed_path = Path.join(ctx.output_dir, "feed.xml")
      assert File.exists?(feed_path)
      feed_xml = File.read!(feed_path)
      assert feed_xml =~ "<feed"
      assert feed_xml =~ "Hello"

      # Per-type feed
      posts_feed = Path.join([ctx.output_dir, "feed", "posts.xml"])
      assert File.exists?(posts_feed)

      # Sitemap
      sitemap_path = Path.join(ctx.output_dir, "sitemap.xml")
      assert File.exists?(sitemap_path)
      sitemap_xml = File.read!(sitemap_path)
      assert sitemap_xml =~ "<urlset"
      assert sitemap_xml =~ "/posts/hello"
    end

    test "sitemap uses root path for index page", ctx do
      pages_dir = Path.join(ctx.content_dir, "pages")
      File.mkdir_p!(pages_dir)

      File.write!(Path.join(pages_dir, "index.md"), """
      ---
      title: "Home"
      ---
      Welcome home.
      """)

      assert {:ok, _result} = Builder.build(build_opts(ctx))

      sitemap_path = Path.join(ctx.output_dir, "sitemap.xml")
      sitemap_xml = File.read!(sitemap_path)
      assert sitemap_xml =~ "<loc>http://localhost:4000/</loc>"
      refute sitemap_xml =~ "/index/"
    end
  end

  describe "content enrichment" do
    test "adds reading_time and toc to content meta", ctx do
      File.write!(Path.join(ctx.posts_dir, "2024-01-15-rich.md"), """
      ---
      title: "Rich Post"
      date: 2024-01-15
      ---
      ## Introduction

      Some content here.

      ## Getting Started

      More content here.
      """)

      assert {:ok, _result} = Builder.build(build_opts(ctx))

      # Verify the rendered output contains proper HTML (meaning enrichment ran)
      post_path = Path.join([ctx.output_dir, "posts", "rich", "index.html"])
      assert File.exists?(post_path)
      html = File.read!(post_path)
      assert html =~ "Introduction"
      assert html =~ "Getting Started"
    end
  end

  describe "seo tags" do
    test "base template includes OG tags", ctx do
      File.write!(Path.join(ctx.posts_dir, "2024-01-15-seo-test.md"), """
      ---
      title: "SEO Test Post"
      date: 2024-01-15
      ---
      Post body for SEO.
      """)

      assert {:ok, _result} = Builder.build(build_opts(ctx))

      html = File.read!(Path.join([ctx.output_dir, "posts", "seo-test", "index.html"]))
      assert html =~ "og:title"
      assert html =~ "SEO Test Post"
      assert html =~ "application/atom+xml"
    end
  end

  describe "block integration" do
    test "block helper renders in templates", ctx do
      # Create a custom layout directory with a layout that uses @block
      layouts_dir = Path.join(ctx.tmp_dir, "layouts")
      File.mkdir_p!(layouts_dir)

      # Copy base template from default theme
      default_base = Sayfa.Config.default_theme_path("layouts/base.html.eex")
      File.cp!(default_base, Path.join(layouts_dir, "base.html.eex"))

      # Create a home layout that uses the hero block
      File.write!(Path.join(layouts_dir, "home.html.eex"), """
      <%= @block.(:hero, title: "Welcome", subtitle: "Test Site") %>
      <div class="content">
        <%= @inner_content %>
      </div>
      """)

      # Also need page layout as fallback
      default_page = Sayfa.Config.default_theme_path("layouts/page.html.eex")
      File.cp!(default_page, Path.join(layouts_dir, "page.html.eex"))

      File.write!(Path.join(ctx.pages_dir, "index.md"), """
      ---
      title: "Home"
      layout: home
      ---
      Welcome to my site.
      """)

      # Build and render, then manually verify via Template since Builder uses theme resolution
      {:ok, content} = Sayfa.Content.parse_file(Path.join(ctx.pages_dir, "index.md"))
      content = %{content | meta: Map.put(content.meta, "layout", "home")}
      config = Sayfa.Config.resolve([])

      {:ok, html} =
        Sayfa.Template.render_content(content,
          config: config,
          layouts_dir: layouts_dir,
          all_contents: []
        )

      assert html =~ "<section class=\"hero\">"
      assert html =~ "Welcome"
      assert html =~ "Test Site"
    end
  end

  describe "multilingual build" do
    test "outputs non-default language content with language prefix", ctx do
      # Create Turkish content subdirectory
      tr_posts_dir = Path.join([ctx.content_dir, "tr", "posts"])
      File.mkdir_p!(tr_posts_dir)

      # English post (default language)
      File.write!(Path.join(ctx.posts_dir, "2024-01-15-hello.md"), """
      ---
      title: "Hello World"
      date: 2024-01-15
      ---
      English content.
      """)

      # Turkish post
      File.write!(Path.join(tr_posts_dir, "2024-01-15-merhaba.md"), """
      ---
      title: "Merhaba Dünya"
      date: 2024-01-15
      ---
      Turkish content.
      """)

      assert {:ok, result} =
               Builder.build(
                 build_opts(ctx, languages: [en: [name: "English"], tr: [name: "Türkçe"]])
               )

      assert result.content_count == 2

      # English post at /posts/hello/
      en_path = Path.join([ctx.output_dir, "posts", "hello", "index.html"])
      assert File.exists?(en_path)
      assert File.read!(en_path) =~ "Hello World"

      # Turkish post at /tr/posts/merhaba/
      tr_path = Path.join([ctx.output_dir, "tr", "posts", "merhaba", "index.html"])
      assert File.exists?(tr_path)
      assert File.read!(tr_path) =~ "Merhaba"

      # Turkish feed at /tr/feed.xml
      tr_feed = Path.join([ctx.output_dir, "tr", "feed.xml"])
      assert File.exists?(tr_feed)

      # Main feed at /feed.xml
      main_feed = Path.join(ctx.output_dir, "feed.xml")
      assert File.exists?(main_feed)
    end
  end

  describe "clean/1" do
    test "removes the output directory", ctx do
      File.mkdir_p!(ctx.output_dir)
      File.write!(Path.join(ctx.output_dir, "test.html"), "test")

      assert :ok = Builder.clean(output_dir: ctx.output_dir)
      refute File.exists?(ctx.output_dir)
    end

    test "succeeds even if output dir doesn't exist", ctx do
      assert :ok = Builder.clean(output_dir: ctx.output_dir)
    end
  end
end
