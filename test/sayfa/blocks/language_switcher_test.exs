defmodule Sayfa.Blocks.LanguageSwitcherTest do
  use ExUnit.Case, async: true

  alias Sayfa.Blocks.LanguageSwitcher
  alias Sayfa.Content

  @multi_lang_site %{
    default_lang: :en,
    languages: [en: [name: "English"], tr: [name: "Türkçe"]]
  }

  @single_lang_site %{
    default_lang: :en,
    languages: [en: [name: "English"]]
  }

  describe "render/1" do
    test "returns empty string with single language" do
      assigns = %{site: @single_lang_site, content: nil, lang: :en}

      assert "" == LanguageSwitcher.render(assigns)
    end

    test "renders dropdown switcher for content with hreflang alternates" do
      content = %Content{
        title: "Hello",
        body: "<p>Hello</p>",
        slug: "hello",
        lang: :en,
        meta: %{
          "hreflang_alternates" => [
            {"en", "/posts/hello/"},
            {"tr", "/tr/posts/hello/"}
          ]
        }
      }

      assigns = %{site: @multi_lang_site, content: content, lang: :en}
      html = LanguageSwitcher.render(assigns)

      assert html =~ "English"
      assert html =~ "Türkçe"
      assert html =~ "/tr/posts/hello/"
      assert html =~ ~s(id="lang-switcher")
      assert html =~ ~s(id="lang-toggle")
      assert html =~ ~s(id="lang-menu")
      assert html =~ ~s(aria-haspopup="listbox")
      assert html =~ ~s(aria-label="Language")
    end

    test "dropdown contains all language options" do
      content = %Content{
        title: "Hello",
        body: "<p>Hello</p>",
        slug: "hello",
        lang: :en,
        meta: %{
          "hreflang_alternates" => [
            {"en", "/posts/hello/"},
            {"tr", "/tr/posts/hello/"}
          ]
        }
      }

      assigns = %{site: @multi_lang_site, content: content, lang: :en}
      html = LanguageSwitcher.render(assigns)

      assert html =~ "English"
      assert html =~ "Türkçe"
      assert html =~ ~s(role="listbox")
    end

    test "current language is highlighted as non-clickable span in dropdown" do
      content = %Content{
        title: "Hello",
        body: "<p>Hello</p>",
        slug: "hello",
        lang: :en,
        meta: %{
          "hreflang_alternates" => [
            {"en", "/posts/hello/"},
            {"tr", "/tr/posts/hello/"}
          ]
        }
      }

      assigns = %{site: @multi_lang_site, content: content, lang: :en}
      html = LanguageSwitcher.render(assigns)

      assert html =~ ~s(<span class="block px-3 py-2 text-sm font-medium)
      assert html =~ "English</span>"
      assert html =~ ~s(<a href="/tr/posts/hello/")
    end

    test "shows uppercase current language code on trigger button" do
      content = %Content{
        title: "Hello",
        body: "<p>Hello</p>",
        slug: "hello",
        lang: :en,
        meta: %{
          "hreflang_alternates" => [
            {"en", "/posts/hello/"},
            {"tr", "/tr/posts/hello/"}
          ]
        }
      }

      assigns = %{site: @multi_lang_site, content: content, lang: :en}
      html = LanguageSwitcher.render(assigns)

      assert html =~ ">EN</span>"
    end

    test "renders switcher for list pages using page_url" do
      assigns = %{
        site: @multi_lang_site,
        content: nil,
        lang: :en,
        page_url: "/posts/"
      }

      html = LanguageSwitcher.render(assigns)

      assert html =~ "English"
      assert html =~ "Türkçe"
      assert html =~ "/tr/posts/"
    end

    test "hides switcher for content without hreflang (no translation exists)" do
      content = %Content{
        title: "About",
        body: "<p>About</p>",
        slug: "about",
        lang: :en,
        meta: %{"content_type" => "pages"}
      }

      assigns = %{
        site: @multi_lang_site,
        content: content,
        lang: :en,
        page_url: "/about/"
      }

      assert "" == LanguageSwitcher.render(assigns)
    end

    test "hides switcher for non-default language content without hreflang" do
      content = %Content{
        title: "Hakkımda",
        body: "<p>Hakkımda</p>",
        slug: "about",
        lang: :tr,
        meta: %{"content_type" => "pages"}
      }

      assigns = %{
        site: @multi_lang_site,
        content: content,
        lang: :tr,
        page_url: "/tr/about/"
      }

      assert "" == LanguageSwitcher.render(assigns)
    end

    test "returns empty for list pages without page_url" do
      assigns = %{site: @multi_lang_site, content: nil, lang: :en}
      html = LanguageSwitcher.render(assigns)

      assert "" == html
    end

    test "dropdown panel is hidden by default" do
      content = %Content{
        title: "Hello",
        body: "<p>Hello</p>",
        slug: "hello",
        lang: :en,
        meta: %{
          "hreflang_alternates" => [
            {"en", "/posts/hello/"},
            {"tr", "/tr/posts/hello/"}
          ]
        }
      }

      assigns = %{site: @multi_lang_site, content: content, lang: :en}
      html = LanguageSwitcher.render(assigns)

      assert html =~ ~s(id="lang-menu" class="hidden)
      assert html =~ ~s(aria-expanded="false")
    end
  end
end
