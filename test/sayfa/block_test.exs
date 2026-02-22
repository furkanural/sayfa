defmodule Sayfa.BlockTest do
  use ExUnit.Case, async: true

  alias Sayfa.Block
  alias Sayfa.Blocks.Breadcrumb
  alias Sayfa.Blocks.CodeCopy
  alias Sayfa.Blocks.CopyLink
  alias Sayfa.Blocks.Footer
  alias Sayfa.Blocks.Header
  alias Sayfa.Blocks.Hero
  alias Sayfa.Blocks.ReadingTime, as: ReadingTimeBlock
  alias Sayfa.Blocks.RecentContent
  alias Sayfa.Blocks.RecentPosts
  alias Sayfa.Blocks.Search
  alias Sayfa.Blocks.SocialLinks
  alias Sayfa.Blocks.TagCloud
  alias Sayfa.Blocks.TOC, as: TOCBlock
  alias Sayfa.Content

  describe "default_blocks/0" do
    test "returns 16 built-in blocks" do
      assert length(Block.default_blocks()) == 16
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

  describe "social_icon/2" do
    @brand_platforms [
      {"github", "GitHub"},
      {"twitter", "X/Twitter"},
      {"x", "X/Twitter"},
      {"mastodon", "Mastodon"},
      {"goodreads", "Goodreads"},
      {"linkedin", "LinkedIn"},
      {"linked in", "LinkedIn"},
      {"youtube", "YouTube"},
      {"yt", "YouTube"},
      {"instagram", "Instagram"},
      {"ig", "Instagram"},
      {"bluesky", "Bluesky"},
      {"bsky", "Bluesky"},
      {"threads", "Threads"},
      {"discord", "Discord"},
      {"reddit", "Reddit"},
      {"stackoverflow", "Stack Overflow"},
      {"stack overflow", "Stack Overflow"},
      {"so", "Stack Overflow"},
      {"facebook", "Facebook"},
      {"fb", "Facebook"},
      {"medium", "Medium"},
      {"dev.to", "Dev.to"},
      {"devto", "Dev.to"},
      {"dev", "Dev.to"},
      {"telegram", "Telegram"},
      {"tg", "Telegram"},
      {"kofi", "Ko-fi"},
      {"ko-fi", "Ko-fi"},
      {"codeberg", "Codeberg"},
      {"letterboxd", "Letterboxd"},
      {"spotify", "Spotify"},
      {"hackernews", "Hacker News"},
      {"hacker news", "Hacker News"},
      {"hn", "Hacker News"},
      {"twitch", "Twitch"}
    ]

    for {label, platform} <- @brand_platforms do
      test "renders filled SVG for #{platform} (#{label})" do
        svg = Block.social_icon(unquote(label))
        assert svg =~ "<svg"
        assert svg =~ ~s(fill="currentColor")
        assert svg =~ ~s(stroke="none")
      end
    end

    test "aliases return the same icon" do
      assert Block.social_icon("linkedin") == Block.social_icon("linked in")
      assert Block.social_icon("youtube") == Block.social_icon("yt")
      assert Block.social_icon("instagram") == Block.social_icon("ig")
      assert Block.social_icon("bluesky") == Block.social_icon("bsky")
      assert Block.social_icon("stackoverflow") == Block.social_icon("stack overflow")
      assert Block.social_icon("stackoverflow") == Block.social_icon("so")
      assert Block.social_icon("facebook") == Block.social_icon("fb")
      assert Block.social_icon("dev.to") == Block.social_icon("devto")
      assert Block.social_icon("dev.to") == Block.social_icon("dev")
      assert Block.social_icon("telegram") == Block.social_icon("tg")
      assert Block.social_icon("kofi") == Block.social_icon("ko-fi")
      assert Block.social_icon("hackernews") == Block.social_icon("hacker news")
      assert Block.social_icon("hackernews") == Block.social_icon("hn")
    end

    test "is case-insensitive" do
      assert Block.social_icon("GitHub") == Block.social_icon("github")
      assert Block.social_icon("LinkedIn") == Block.social_icon("linkedin")
      assert Block.social_icon("YOUTUBE") == Block.social_icon("youtube")
    end

    test "custom size parameter" do
      svg = Block.social_icon("github", "w-8 h-8")
      assert svg =~ ~s(class="w-8 h-8")
    end

    test "utility icons use outlined style" do
      for label <- ["email", "rss", "feed"] do
        svg = Block.social_icon(label)
        assert svg =~ ~s(fill="none")
        assert svg =~ ~s(stroke="currentColor")
        assert svg =~ ~s(stroke-width="1.5")
      end
    end

    test "fallback for unknown platforms uses outlined style" do
      svg = Block.social_icon("unknown-platform")
      assert svg =~ "<svg"
      assert svg =~ ~s(fill="none")
      assert svg =~ ~s(stroke="currentColor")
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

    test "language switcher appears next to hamburger in mobile layout" do
      html =
        Header.render(%{
          site: %{
            title: "Blog",
            default_lang: :en,
            languages: [en: [name: "English"], tr: [name: "Türkçe"]]
          },
          nav: [{"Home", "/"}],
          lang: :en,
          page_url: "/posts/"
        })

      assert html =~ ~s(id="lang-switcher")
      assert html =~ ~s(id="menu-toggle")
    end

    test "site title links to /tr/ for non-default language" do
      html = Header.render(%{site: %{title: "Blog", default_lang: :en}, lang: :tr})
      assert html =~ ~s(href="/tr/")
    end

    test "site title links to / for default language" do
      html = Header.render(%{site: %{title: "Blog", default_lang: :en}, lang: :en})
      assert html =~ ~s(href="/")
      refute html =~ ~s(href="/en/")
    end

    test "nav URLs get prefixed with /tr/ for non-default language" do
      html =
        Header.render(%{
          site: %{title: "Blog", default_lang: :en},
          lang: :tr,
          nav: [{"Ana Sayfa", "/"}, {"Yazılar", "/posts/"}]
        })

      assert html =~ ~s(href="/tr/")
      assert html =~ ~s(href="/tr/posts/")
    end

    test "nav URLs already containing lang prefix are not double-prefixed" do
      html =
        Header.render(%{
          site: %{title: "Blog", default_lang: :en},
          lang: :tr,
          nav: [{"Yazılar", "/tr/posts/"}]
        })

      assert html =~ ~s(href="/tr/posts/")
      refute html =~ ~s(href="/tr/tr/posts/")
    end

    test "applies active class to current nav item" do
      html =
        Header.render(%{
          site: %{title: "Blog", default_lang: :en},
          lang: :en,
          nav: [{"Home", "/"}, {"Posts", "/posts/"}, {"About", "/about/"}],
          page_url: "/posts/hello-world/"
        })

      # "Posts" link should have active styling (font-medium text-slate-900)
      assert html =~ ~r/href="\/posts\/"[^>]*font-medium text-slate-900/
      # "Home" and "About" should not have active styling
      assert html =~ ~r/href="\/"[^>]*text-slate-500/
      assert html =~ ~r/href="\/about\/"[^>]*text-slate-500/
    end

    test "applies active class to home only for exact /" do
      html =
        Header.render(%{
          site: %{title: "Blog", default_lang: :en},
          lang: :en,
          nav: [{"Home", "/"}, {"Posts", "/posts/"}],
          page_url: "/"
        })

      # Home should be active
      assert html =~ ~r/href="\/"[^>]*font-medium text-slate-900/
      # Posts should not be active
      assert html =~ ~r/href="\/posts\/"[^>]*text-slate-500/
    end

    test "no active class when page_url is nil" do
      html =
        Header.render(%{
          site: %{title: "Blog", default_lang: :en},
          lang: :en,
          nav: [{"Home", "/"}, {"Posts", "/posts/"}],
          page_url: nil
        })

      # All items should have default styling
      refute html =~ "font-medium text-slate-900"
    end

    test "active state works with language-prefixed URLs" do
      html =
        Header.render(%{
          site: %{title: "Blog", default_lang: :en},
          lang: :tr,
          nav: [{"Ana Sayfa", "/"}, {"Yazılar", "/posts/"}],
          page_url: "/tr/posts/merhaba/"
        })

      # Yazılar should be active (its URL becomes /tr/posts/ which matches /tr/posts/merhaba/)
      assert html =~ ~r/href="\/tr\/posts\/"[^>]*font-medium text-slate-900/
    end

    test "localized homepage is not active on subpages" do
      html =
        Header.render(%{
          site: %{title: "Blog", default_lang: :en},
          lang: :tr,
          nav: [{"Ana Sayfa", "/"}, {"Yazılar", "/posts/"}],
          page_url: "/tr/posts/"
        })

      # Ana Sayfa (/tr/) should NOT be active when on /tr/posts/
      assert html =~ ~r/href="\/tr\/"[^>]*text-slate-500/
      # Yazılar should be active
      assert html =~ ~r/href="\/tr\/posts\/"[^>]*font-medium text-slate-900/
    end

    test "localized homepage is active on exact match" do
      html =
        Header.render(%{
          site: %{title: "Blog", default_lang: :en},
          lang: :tr,
          nav: [{"Ana Sayfa", "/"}, {"Yazılar", "/posts/"}],
          page_url: "/tr/"
        })

      # Ana Sayfa should be active on /tr/
      assert html =~ ~r/href="\/tr\/"[^>]*font-medium text-slate-900/
      # Yazılar should NOT be active
      assert html =~ ~r/href="\/tr\/posts\/"[^>]*text-slate-500/
    end

    test "nav URLs are unchanged for default language" do
      html =
        Header.render(%{
          site: %{title: "Blog", default_lang: :en},
          lang: :en,
          nav: [{"Home", "/"}, {"Posts", "/posts/"}]
        })

      assert html =~ ~s(href="/")
      assert html =~ ~s(href="/posts/")
      refute html =~ ~s(href="/en/)
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

    test "renders Goodreads icon with aria-label" do
      html =
        Footer.render(%{
          site: %{
            title: "Blog",
            social_links: [{"Goodreads", "https://goodreads.com/test"}]
          }
        })

      assert html =~ "aria-label=\"Goodreads\""
      assert html =~ "https://goodreads.com/test"
      assert html =~ "<svg"
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

    test "renders Goodreads with icon and label" do
      html =
        SocialLinks.render(%{
          links: [{"Goodreads", "https://goodreads.com/test"}]
        })

      assert html =~ "Goodreads"
      assert html =~ "https://goodreads.com/test"
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

    test "filters contents by language" do
      contents = [
        %Content{
          title: "English Post",
          body: "",
          date: ~D[2024-06-01],
          slug: "english-post",
          lang: :en,
          meta: %{"content_type" => "posts", "url_prefix" => "posts"}
        },
        %Content{
          title: "Turkish Post",
          body: "",
          date: ~D[2024-06-01],
          slug: "turkish-post",
          lang: :tr,
          meta: %{"content_type" => "posts", "url_prefix" => "posts", "lang_prefix" => "tr"}
        }
      ]

      html =
        RecentPosts.render(%{
          contents: contents,
          lang: :tr,
          site: %{default_lang: :en}
        })

      assert html =~ "Turkish Post"
      refute html =~ "English Post"
    end

    test "view all link includes lang prefix for non-default language" do
      contents = [
        %Content{
          title: "Turkish Post",
          body: "",
          date: ~D[2024-06-01],
          slug: "post",
          lang: :tr,
          meta: %{"content_type" => "posts", "url_prefix" => "posts", "lang_prefix" => "tr"}
        }
      ]

      html =
        RecentPosts.render(%{
          contents: contents,
          lang: :tr,
          site: %{default_lang: :en},
          show_view_all: true
        })

      assert html =~ ~s(href="/tr/posts/")
    end

    test "view all link has no prefix for default language" do
      contents = [
        %Content{
          title: "English Post",
          body: "",
          date: ~D[2024-06-01],
          slug: "post",
          lang: :en,
          meta: %{"content_type" => "posts", "url_prefix" => "posts"}
        }
      ]

      html =
        RecentPosts.render(%{
          contents: contents,
          lang: :en,
          site: %{default_lang: :en},
          show_view_all: true
        })

      assert html =~ ~s(href="/posts/")
      refute html =~ ~s(href="/en/posts/")
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
      html = ReadingTimeBlock.render(%{content: content, lang: :en, site: %{default_lang: :en}})
      assert html =~ "inline-flex items-center"
      assert html =~ "5 min read"
      assert html =~ "<svg"
    end

    test "renders singular for 1 minute" do
      content = %Content{title: "Test", body: "", meta: %{"reading_time" => 1}}
      html = ReadingTimeBlock.render(%{content: content, lang: :en, site: %{default_lang: :en}})
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
    test "renders config div with data attributes" do
      html = CodeCopy.render(%{})
      assert html =~ ~s(id="sayfa-code-copy")
      assert html =~ ~s(data-selector="pre code")
      assert html =~ "hidden"
      refute html =~ "<script>"
    end

    test "uses custom selector" do
      html = CodeCopy.render(%{selector: ".highlight code"})
      assert html =~ ~s(data-selector=".highlight code")
    end
  end

  describe "CopyLink" do
    test "renders copy link button" do
      html = CopyLink.render(%{})
      assert html =~ "Copy link"
      assert html =~ "clipboard"
      assert html =~ "<button"
      assert html =~ "cursor-pointer"
    end
  end

  describe "Breadcrumb" do
    test "renders section link without lang_prefix" do
      content = %Content{
        title: "Hello World",
        body: "",
        meta: %{"url_prefix" => "posts", "lang_prefix" => ""}
      }

      html = Breadcrumb.render(%{content: content, site: %{base_url: "https://example.com"}})
      assert html =~ ~s(href="/posts/")
      assert html =~ ~s(href="/")
      refute html =~ ~s(href="/tr/)
    end

    test "renders section link with lang_prefix" do
      content = %Content{
        title: "Merhaba",
        body: "",
        meta: %{"url_prefix" => "posts", "lang_prefix" => "tr"}
      }

      html = Breadcrumb.render(%{content: content, site: %{base_url: "https://example.com"}})
      assert html =~ ~s(href="/tr/posts/")
      assert html =~ ~s(href="/tr/")
    end

    test "renders home link to /tr/ for page with lang_prefix" do
      content = %Content{
        title: "Hakkımda",
        body: "",
        meta: %{"url_prefix" => "", "lang_prefix" => "tr"}
      }

      html = Breadcrumb.render(%{content: content, site: %{base_url: "https://example.com"}})
      assert html =~ ~s(href="/tr/")
    end

    test "section name uses translation function" do
      content = %Content{
        title: "Phoenix LiveView Temelleri",
        body: "",
        meta: %{"url_prefix" => "posts", "lang_prefix" => "tr"}
      }

      custom_t = fn
        "home" -> "Ana Sayfa"
        "posts_title" -> "Yazılar"
        key -> key
      end

      html =
        Breadcrumb.render(%{
          content: content,
          site: %{base_url: "https://example.com"},
          t: custom_t
        })

      assert html =~ "Yazılar"
      assert html =~ "Ana Sayfa"
      refute html =~ ">Posts<"
    end

    test "JSON-LD uses language-aware home URL" do
      content = %Content{
        title: "Merhaba",
        body: "",
        meta: %{"url_prefix" => "posts", "lang_prefix" => "tr"}
      }

      html = Breadcrumb.render(%{content: content, site: %{base_url: "https://example.com"}})
      assert html =~ ~s("item":"https://example.com/tr/")
      assert html =~ ~s("item":"https://example.com/tr/posts/")
    end
  end

  describe "RecentContent" do
    test "filters contents by language" do
      contents = [
        %Content{
          title: "English Post",
          body: "",
          date: ~D[2024-06-01],
          slug: "english-post",
          lang: :en,
          meta: %{"content_type" => "posts", "url_prefix" => "posts"}
        },
        %Content{
          title: "Turkish Post",
          body: "",
          date: ~D[2024-06-01],
          slug: "turkish-post",
          lang: :tr,
          meta: %{"content_type" => "posts", "url_prefix" => "posts", "lang_prefix" => "tr"}
        }
      ]

      html =
        RecentContent.render(%{
          contents: contents,
          lang: :tr,
          site: %{default_lang: :en}
        })

      assert html =~ "Turkish Post"
      refute html =~ "English Post"
    end

    test "view all links include lang prefix for non-default language" do
      contents = [
        %Content{
          title: "Turkish Post",
          body: "",
          date: ~D[2024-06-01],
          slug: "post",
          lang: :tr,
          meta: %{"content_type" => "posts", "url_prefix" => "posts", "lang_prefix" => "tr"}
        }
      ]

      html =
        RecentContent.render(%{
          contents: contents,
          lang: :tr,
          site: %{default_lang: :en}
        })

      assert html =~ ~s(href="/tr/posts/")
    end

    test "section headings use translation function" do
      contents = [
        %Content{
          title: "Merhaba",
          body: "",
          date: ~D[2024-06-01],
          slug: "merhaba",
          lang: :tr,
          meta: %{"content_type" => "posts", "url_prefix" => "posts", "lang_prefix" => "tr"}
        }
      ]

      custom_t = fn
        "posts_title" -> "Yazılar"
        "view_all" -> "Tümünü gör"
        key -> key
      end

      html =
        RecentContent.render(%{
          contents: contents,
          lang: :tr,
          site: %{default_lang: :en},
          t: custom_t
        })

      assert html =~ "Yazılar"
      refute html =~ ">Posts<"
    end

    test "view all links have no prefix for default language" do
      contents = [
        %Content{
          title: "English Post",
          body: "",
          date: ~D[2024-06-01],
          slug: "post",
          lang: :en,
          meta: %{"content_type" => "posts", "url_prefix" => "posts"}
        }
      ]

      html =
        RecentContent.render(%{
          contents: contents,
          lang: :en,
          site: %{default_lang: :en}
        })

      assert html =~ ~s(href="/posts/")
      refute html =~ ~s(href="/en/posts/")
    end
  end

  describe "Search" do
    test "renders search modal with defaults" do
      html = Search.render(%{})
      assert html =~ ~s(id="search-modal")
      assert html =~ ~s(role="dialog")
      assert html =~ ~s(aria-modal="true")
      assert html =~ ~s(id="search-backdrop")
      assert html =~ ~s(id="search-esc")
      assert html =~ ~s(id="search-footer")
      assert html =~ ~s(<div id="search")
      assert html =~ ~s(data-show-sub-results="true")
      assert html =~ ~s(data-show-images="true")
      refute html =~ "<script>"
    end

    test "renders with custom options" do
      html = Search.render(%{show_sub_results: false, show_images: false})
      assert html =~ ~s(data-show-sub-results="false")
      assert html =~ ~s(data-show-images="false")
    end

    test "uses translation function for labels" do
      t = fn
        "search" -> "Ara"
        "search_placeholder" -> "Ara..."
        "search_no_results" -> "Sonuç bulunamadı"
        key -> key
      end

      html = Search.render(%{t: t})
      assert html =~ "Ara"
      assert html =~ ~s(data-placeholder="Ara...")
      assert html =~ ~s(data-no-results="Sonuç bulunamadı")
    end

    test "render_trigger returns search button" do
      html = Search.render_trigger(%{})
      assert html =~ ~s(id="search-trigger")
      assert html =~ ~s(aria-label="Search")
      assert html =~ "<svg"
      assert html =~ "<circle"
    end

    test "render_trigger uses translation function" do
      t = fn
        "search" -> "Ara"
        key -> key
      end

      html = Search.render_trigger(%{t: t})
      assert html =~ ~s(aria-label="Ara")
    end
  end
end
