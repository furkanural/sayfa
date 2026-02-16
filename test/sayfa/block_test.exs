defmodule Sayfa.BlockTest do
  use ExUnit.Case, async: true

  alias Sayfa.Block
  alias Sayfa.Blocks.CodeCopy
  alias Sayfa.Blocks.CopyLink
  alias Sayfa.Blocks.Footer
  alias Sayfa.Blocks.Header
  alias Sayfa.Blocks.Hero
  alias Sayfa.Blocks.ReadingTime, as: ReadingTimeBlock
  alias Sayfa.Blocks.RecentPosts
  alias Sayfa.Blocks.Search
  alias Sayfa.Blocks.SocialLinks
  alias Sayfa.Blocks.TagCloud
  alias Sayfa.Blocks.TOC, as: TOCBlock
  alias Sayfa.Content

  describe "default_blocks/0" do
    test "returns 13 built-in blocks" do
      assert length(Block.default_blocks()) == 13
    end

    test "all modules implement the block behaviour" do
      for mod <- Block.default_blocks() do
        assert is_atom(mod.name())
        assert is_binary(mod.render(%{}))
      end
    end
  end

  describe "all/0" do
    test "returns default blocks when no config" do
      assert Block.all() == Block.default_blocks()
    end
  end

  describe "find_by_name/1" do
    test "finds hero block" do
      assert Block.find_by_name(:hero) == Hero
    end

    test "finds all built-in blocks by name" do
      expected_names = [
        :hero,
        :header,
        :footer,
        :social_links,
        :toc,
        :recent_posts,
        :tag_cloud,
        :reading_time,
        :code_copy,
        :recent_content,
        :search,
        :copy_link
      ]

      for name <- expected_names do
        assert Block.find_by_name(name), "Expected to find block #{name}"
      end
    end

    test "returns nil for unknown block" do
      assert Block.find_by_name(:nonexistent) == nil
    end
  end

  describe "build_helper/1" do
    test "returns a function" do
      helper = Block.build_helper(site: %{}, content: nil, contents: [], lang: :en)
      assert is_function(helper, 2)
    end

    test "renders known block" do
      helper = Block.build_helper(site: %{title: "Test"}, content: nil, contents: [], lang: :en)
      result = helper.(:hero, title: "Welcome")
      assert result =~ "Welcome"
      assert result =~ "text-3xl"
    end

    test "returns empty string for unknown block" do
      helper = Block.build_helper(site: %{}, content: nil, contents: [], lang: :en)
      assert helper.(:nonexistent, []) == ""
    end

    test "merges context with caller opts" do
      helper =
        Block.build_helper(site: %{title: "My Site"}, content: nil, contents: [], lang: :en)

      result = helper.(:header, nav: [{"Home", "/"}])
      assert result =~ "My Site"
      assert result =~ "Home"
    end
  end

  describe "escape_html/1" do
    test "escapes special characters" do
      assert Block.escape_html("<script>") == "&lt;script&gt;"
      assert Block.escape_html("a & b") == "a &amp; b"
      assert Block.escape_html("\"quoted\"") == "&quot;quoted&quot;"
      assert Block.escape_html("it's") == "it&#39;s"
    end

    test "returns empty string for nil" do
      assert Block.escape_html(nil) == ""
    end
  end

  # --- Individual Block Tests ---

  describe "Hero" do
    test "renders with title and subtitle" do
      html = Hero.render(%{title: "Hello", subtitle: "World"})
      assert html =~ "text-3xl"
      assert html =~ "Hello"
      assert html =~ "World"
    end

    test "renders without subtitle" do
      html = Hero.render(%{title: "Hello"})
      assert html =~ "Hello"
      refute html =~ "World"
    end

    test "escapes HTML in title" do
      html = Hero.render(%{title: "<script>xss</script>"})
      assert html =~ "&lt;script&gt;"
      refute html =~ "<script>xss"
    end
  end

  describe "Header" do
    test "renders with site title" do
      html = Header.render(%{site: %{title: "My Blog"}})
      assert html =~ "<header class=\"sticky"
      assert html =~ "My Blog"
    end

    test "renders with navigation" do
      html =
        Header.render(%{
          site: %{title: "Blog"},
          nav: [{"Home", "/"}, {"About", "/about/"}]
        })

      assert html =~ "<nav class=\"hidden md:flex"
      assert html =~ "Home"
      assert html =~ "/about/"
    end

    test "renders without navigation" do
      html = Header.render(%{site: %{title: "Blog"}, nav: []})
      refute html =~ "<nav"
    end
  end

  describe "Footer" do
    test "renders with year and author" do
      html = Footer.render(%{year: 2024, author: "Jane"})
      assert html =~ "<footer class=\"border-t"
      assert html =~ "2024"
      assert html =~ "Jane"
    end

    test "falls back to site author" do
      html = Footer.render(%{site: %{author: "Site Author"}})
      assert html =~ "Site Author"
    end

    test "falls back to site title" do
      html = Footer.render(%{site: %{title: "My Blog"}})
      assert html =~ "My Blog"
    end

    test "renders icon-only social links from site config" do
      html =
        Footer.render(%{
          site: %{
            title: "Blog",
            social_links: [{"GitHub", "https://github.com/test"}]
          }
        })

      assert html =~ "aria-label=\"GitHub\""
      assert html =~ "https://github.com/test"
    end
  end

  describe "SocialLinks" do
    test "renders links with icons" do
      html =
        SocialLinks.render(%{
          links: [{"GitHub", "https://github.com"}, {"Twitter", "https://twitter.com"}]
        })

      assert html =~ "<div class=\"flex flex-wrap"
      assert html =~ "GitHub"
      assert html =~ "https://github.com"
      assert html =~ "rel=\"noopener\""
      assert html =~ "<svg"
    end

    test "returns empty string for no links" do
      assert SocialLinks.render(%{links: []}) == ""
      assert SocialLinks.render(%{}) == ""
    end
  end

  describe "TOCBlock" do
    test "renders sidebar table of contents" do
      content = %Content{
        title: "Test",
        body: "",
        meta: %{
          "toc" => [
            %{id: "intro", text: "Introduction", level: 2},
            %{id: "details", text: "Details", level: 3}
          ]
        }
      }

      html = TOCBlock.render(%{content: content})
      assert html =~ "<nav class=\"sticky top-20\""
      assert html =~ "#intro"
      assert html =~ "Introduction"
      assert html =~ "Details"
      assert html =~ "border-l"
    end

    test "renders mobile table of contents" do
      content = %Content{
        title: "Test",
        body: "",
        meta: %{
          "toc" => [
            %{id: "intro", text: "Introduction", level: 2}
          ]
        }
      }

      html = TOCBlock.render(%{content: content, variant: :mobile})
      assert html =~ "<details"
      assert html =~ "<summary"
      assert html =~ "On this page"
      assert html =~ "#intro"
    end

    test "returns empty string when no toc" do
      content = %Content{title: "Test", body: "", meta: %{}}
      assert TOCBlock.render(%{content: content}) == ""
    end

    test "returns empty string when content is nil" do
      assert TOCBlock.render(%{}) == ""
    end
  end

  describe "RecentPosts" do
    test "renders recent posts" do
      contents = [
        %Content{
          title: "Post A",
          body: "",
          date: ~D[2024-06-01],
          slug: "post-a",
          meta: %{"content_type" => "posts", "url_prefix" => "posts"}
        },
        %Content{
          title: "Post B",
          body: "",
          date: ~D[2024-01-01],
          slug: "post-b",
          meta: %{"content_type" => "posts", "url_prefix" => "posts"}
        },
        %Content{title: "Page", body: "", meta: %{"content_type" => "pages"}}
      ]

      html = RecentPosts.render(%{contents: contents, limit: 2})
      assert html =~ "Recent Posts"
      assert html =~ "Post A"
      assert html =~ "Post B"
      refute html =~ "Page"
    end

    test "returns empty string with no posts" do
      assert RecentPosts.render(%{contents: []}) == ""
    end

    test "includes lang_prefix in post URLs" do
      contents = [
        %Content{
          title: "Merhaba",
          body: "",
          date: ~D[2024-06-01],
          slug: "merhaba",
          meta: %{"content_type" => "posts", "url_prefix" => "posts", "lang_prefix" => "tr"}
        }
      ]

      html = RecentPosts.render(%{contents: contents, limit: 5})
      assert html =~ "/tr/posts/merhaba"
    end
  end

  describe "TagCloud" do
    test "renders tag cloud with hash icons" do
      contents = [
        %Content{title: "A", body: "", tags: ["elixir", "otp"]},
        %Content{title: "B", body: "", tags: ["elixir"]}
      ]

      html = TagCloud.render(%{contents: contents})
      assert html =~ "<section class=\"flex flex-wrap"
      assert html =~ "elixir"
      assert html =~ "otp"
      assert html =~ "/tags/"
      assert html =~ "<svg"
    end

    test "returns empty string with no tags" do
      assert TagCloud.render(%{contents: []}) == ""
    end
  end

  describe "ReadingTimeBlock" do
    test "renders reading time with clock icon" do
      content = %Content{title: "Test", body: "", meta: %{"reading_time" => 5}}
      html = ReadingTimeBlock.render(%{content: content})
      assert html =~ "inline-flex items-center"
      assert html =~ "5 min read"
      assert html =~ "<svg"
    end

    test "renders singular for 1 minute" do
      content = %Content{title: "Test", body: "", meta: %{"reading_time" => 1}}
      html = ReadingTimeBlock.render(%{content: content})
      assert html =~ "1 min read"
    end

    test "returns empty string when no reading time" do
      content = %Content{title: "Test", body: "", meta: %{}}
      assert ReadingTimeBlock.render(%{content: content}) == ""
    end

    test "returns empty string when content is nil" do
      assert ReadingTimeBlock.render(%{}) == ""
    end
  end

  describe "CodeCopy" do
    test "renders script tag" do
      html = CodeCopy.render(%{})
      assert html =~ "<script>"
      assert html =~ "clipboard"
      assert html =~ "pre code"
    end

    test "uses custom selector" do
      html = CodeCopy.render(%{selector: ".highlight code"})
      assert html =~ ".highlight code"
    end
  end

  describe "CopyLink" do
    test "renders copy link button" do
      html = CopyLink.render(%{})
      assert html =~ "Copy link"
      assert html =~ "clipboard"
      assert html =~ "<button"
      assert html =~ "border-t"
    end
  end

  describe "Search" do
    test "renders pagefind UI with defaults" do
      html = Search.render(%{})
      assert html =~ ~s(<link href="/pagefind/pagefind-ui.css" rel="stylesheet">)
      assert html =~ ~s(<script src="/pagefind/pagefind-ui.js"></script>)
      assert html =~ ~s(<div id="search"></div>)
      assert html =~ ~s(showSubResults: true)
      assert html =~ ~s(showImages: true)
    end

    test "renders with custom options" do
      html = Search.render(%{show_sub_results: false, show_images: false})
      assert html =~ ~s(showSubResults: false)
      assert html =~ ~s(showImages: false)
    end

    test "renders with custom element selector" do
      html = Search.render(%{element: "#custom-search"})
      assert html =~ ~s(element: "#custom-search")
    end
  end
end
