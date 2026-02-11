defmodule Sayfa.BlockTest do
  use ExUnit.Case, async: true

  alias Sayfa.Block

  describe "default_blocks/0" do
    test "returns 9 built-in blocks" do
      assert length(Block.default_blocks()) == 9
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
      assert Block.find_by_name(:hero) == Sayfa.Blocks.Hero
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
        :code_copy
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
      assert result =~ "<section class=\"hero\">"
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

  describe "Sayfa.Blocks.Hero" do
    test "renders with title and subtitle" do
      html = Sayfa.Blocks.Hero.render(%{title: "Hello", subtitle: "World"})
      assert html =~ "<section class=\"hero\">"
      assert html =~ "<h1>Hello</h1>"
      assert html =~ "<p>World</p>"
    end

    test "renders without subtitle" do
      html = Sayfa.Blocks.Hero.render(%{title: "Hello"})
      assert html =~ "<h1>Hello</h1>"
      refute html =~ "<p>"
    end

    test "escapes HTML in title" do
      html = Sayfa.Blocks.Hero.render(%{title: "<script>xss</script>"})
      assert html =~ "&lt;script&gt;"
      refute html =~ "<script>xss"
    end
  end

  describe "Sayfa.Blocks.Header" do
    test "renders with site title" do
      html = Sayfa.Blocks.Header.render(%{site: %{title: "My Blog"}})
      assert html =~ "<header>"
      assert html =~ "My Blog"
    end

    test "renders with navigation" do
      html =
        Sayfa.Blocks.Header.render(%{
          site: %{title: "Blog"},
          nav: [{"Home", "/"}, {"About", "/about/"}]
        })

      assert html =~ "<nav>"
      assert html =~ "Home"
      assert html =~ "/about/"
    end

    test "renders without navigation" do
      html = Sayfa.Blocks.Header.render(%{site: %{title: "Blog"}})
      refute html =~ "<nav>"
    end
  end

  describe "Sayfa.Blocks.Footer" do
    test "renders with year and author" do
      html = Sayfa.Blocks.Footer.render(%{year: 2024, author: "Jane"})
      assert html =~ "<footer>"
      assert html =~ "2024"
      assert html =~ "Jane"
    end

    test "falls back to site author" do
      html = Sayfa.Blocks.Footer.render(%{site: %{author: "Site Author"}})
      assert html =~ "Site Author"
    end

    test "falls back to site title" do
      html = Sayfa.Blocks.Footer.render(%{site: %{title: "My Blog"}})
      assert html =~ "My Blog"
    end
  end

  describe "Sayfa.Blocks.SocialLinks" do
    test "renders links" do
      html =
        Sayfa.Blocks.SocialLinks.render(%{
          links: [{"GitHub", "https://github.com"}, {"Twitter", "https://twitter.com"}]
        })

      assert html =~ "<ul class=\"social-links\">"
      assert html =~ "GitHub"
      assert html =~ "https://github.com"
      assert html =~ "rel=\"noopener\""
    end

    test "returns empty string for no links" do
      assert Sayfa.Blocks.SocialLinks.render(%{links: []}) == ""
      assert Sayfa.Blocks.SocialLinks.render(%{}) == ""
    end
  end

  describe "Sayfa.Blocks.TOC" do
    test "renders table of contents" do
      content = %Sayfa.Content{
        title: "Test",
        body: "",
        meta: %{
          "toc" => [
            %{id: "intro", text: "Introduction", level: 2},
            %{id: "details", text: "Details", level: 3}
          ]
        }
      }

      html = Sayfa.Blocks.TOC.render(%{content: content})
      assert html =~ "<nav class=\"toc\">"
      assert html =~ "#intro"
      assert html =~ "Introduction"
      assert html =~ "Details"
    end

    test "returns empty string when no toc" do
      content = %Sayfa.Content{title: "Test", body: "", meta: %{}}
      assert Sayfa.Blocks.TOC.render(%{content: content}) == ""
    end

    test "returns empty string when content is nil" do
      assert Sayfa.Blocks.TOC.render(%{}) == ""
    end
  end

  describe "Sayfa.Blocks.RecentPosts" do
    test "renders recent posts" do
      contents = [
        %Sayfa.Content{
          title: "Post A",
          body: "",
          date: ~D[2024-06-01],
          slug: "post-a",
          meta: %{"content_type" => "posts", "url_prefix" => "posts"}
        },
        %Sayfa.Content{
          title: "Post B",
          body: "",
          date: ~D[2024-01-01],
          slug: "post-b",
          meta: %{"content_type" => "posts", "url_prefix" => "posts"}
        },
        %Sayfa.Content{title: "Page", body: "", meta: %{"content_type" => "pages"}}
      ]

      html = Sayfa.Blocks.RecentPosts.render(%{contents: contents, limit: 2})
      assert html =~ "<section class=\"recent-posts\">"
      assert html =~ "Post A"
      assert html =~ "Post B"
      refute html =~ "Page"
    end

    test "returns empty string with no posts" do
      assert Sayfa.Blocks.RecentPosts.render(%{contents: []}) == ""
    end
  end

  describe "Sayfa.Blocks.TagCloud" do
    test "renders tag cloud" do
      contents = [
        %Sayfa.Content{title: "A", body: "", tags: ["elixir", "otp"]},
        %Sayfa.Content{title: "B", body: "", tags: ["elixir"]}
      ]

      html = Sayfa.Blocks.TagCloud.render(%{contents: contents})
      assert html =~ "<section class=\"tag-cloud\">"
      assert html =~ "elixir"
      assert html =~ "otp"
      assert html =~ "/tags/"
    end

    test "returns empty string with no tags" do
      assert Sayfa.Blocks.TagCloud.render(%{contents: []}) == ""
    end
  end

  describe "Sayfa.Blocks.ReadingTime" do
    test "renders reading time from meta" do
      content = %Sayfa.Content{title: "Test", body: "", meta: %{"reading_time" => 5}}
      html = Sayfa.Blocks.ReadingTime.render(%{content: content})
      assert html =~ "<span class=\"reading-time\">"
      assert html =~ "5 min read"
    end

    test "renders singular for 1 minute" do
      content = %Sayfa.Content{title: "Test", body: "", meta: %{"reading_time" => 1}}
      html = Sayfa.Blocks.ReadingTime.render(%{content: content})
      assert html =~ "1 min read"
    end

    test "returns empty string when no reading time" do
      content = %Sayfa.Content{title: "Test", body: "", meta: %{}}
      assert Sayfa.Blocks.ReadingTime.render(%{content: content}) == ""
    end

    test "returns empty string when content is nil" do
      assert Sayfa.Blocks.ReadingTime.render(%{}) == ""
    end
  end

  describe "Sayfa.Blocks.CodeCopy" do
    test "renders script tag" do
      html = Sayfa.Blocks.CodeCopy.render(%{})
      assert html =~ "<script>"
      assert html =~ "clipboard"
      assert html =~ "pre code"
    end

    test "uses custom selector" do
      html = Sayfa.Blocks.CodeCopy.render(%{selector: ".highlight code"})
      assert html =~ ".highlight code"
    end
  end
end
