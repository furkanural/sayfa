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
            {"en", "/articles/hello/"},
            {"tr", "/tr/articles/hello/"}
          ]
        }
      }

      assigns = %{site: @multi_lang_site, content: content, lang: :en}
      html = LanguageSwitcher.render(assigns)

      assert html =~ "English"
      assert html =~ "Türkçe"
      assert html =~ "/tr/articles/hello/"
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
            {"en", "/articles/hello/"},
            {"tr", "/tr/articles/hello/"}
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
            {"en", "/articles/hello/"},
            {"tr", "/tr/articles/hello/"}
          ]
        }
      }

      assigns = %{site: @multi_lang_site, content: content, lang: :en}
      html = LanguageSwitcher.render(assigns)

      assert html =~ ~s(<span class="lang-item-current)
      assert html =~ "English</span>"
      assert html =~ ~s(<a href="/tr/articles/hello/")
    end

    test "shows uppercase current language code on trigger button" do
      content = %Content{
        title: "Hello",
        body: "<p>Hello</p>",
        slug: "hello",
        lang: :en,
        meta: %{
          "hreflang_alternates" => [
            {"en", "/articles/hello/"},
            {"tr", "/tr/articles/hello/"}
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
        page_url: "/articles/"
      }

      html = LanguageSwitcher.render(assigns)

      assert html =~ "English"
      assert html =~ "Türkçe"
      assert html =~ "/tr/articles/"
    end

    test "falls back to home paths for content without hreflang" do
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

      html = LanguageSwitcher.render(assigns)

      # Current lang (EN) rendered as non-clickable span; other lang gets home link
      assert html =~ ~s(lang-item-current)
      assert html =~ "English"
      assert html =~ ~s(href="/tr/")
    end

    test "falls back to home paths for non-default lang content without hreflang" do
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

      html = LanguageSwitcher.render(assigns)

      # Current lang (TR) rendered as non-clickable span; default lang gets home link
      assert html =~ ~s(href="/")
      assert html =~ ~s(lang-item-current)
      assert html =~ "Türkçe"
    end

    test "falls back to home paths for list pages without page_url" do
      assigns = %{site: @multi_lang_site, content: nil, lang: :en}
      html = LanguageSwitcher.render(assigns)

      # Current lang (EN) rendered as non-clickable span; other lang gets home link
      assert html =~ ~s(lang-item-current)
      assert html =~ "English"
      assert html =~ ~s(href="/tr/")
    end

    test "dropdown panel is hidden by default" do
      content = %Content{
        title: "Hello",
        body: "<p>Hello</p>",
        slug: "hello",
        lang: :en,
        meta: %{
          "hreflang_alternates" => [
            {"en", "/articles/hello/"},
            {"tr", "/tr/articles/hello/"}
          ]
        }
      }

      assigns = %{site: @multi_lang_site, content: content, lang: :en}
      html = LanguageSwitcher.render(assigns)

      assert html =~ ~s(id="lang-menu" class="lang-menu is-hidden)
      assert html =~ ~s(aria-expanded="false")
    end

    test "render/1 with variant parameter generates unique IDs" do
      content = %Content{
        title: "Hello",
        body: "<p>Hello</p>",
        slug: "hello",
        lang: :en,
        meta: %{
          "hreflang_alternates" => [
            {"en", "/articles/hello/"},
            {"tr", "/tr/articles/hello/"}
          ]
        }
      }

      assigns = %{site: @multi_lang_site, content: content, lang: :en, variant: :mobile}
      html = LanguageSwitcher.render(assigns)

      assert html =~ ~s(id="lang-switcher-mobile")
      assert html =~ ~s(id="lang-toggle-mobile")
      assert html =~ ~s(id="lang-menu-mobile")
    end

    test "render/1 without variant uses default IDs" do
      content = %Content{
        title: "Hello",
        body: "<p>Hello</p>",
        slug: "hello",
        lang: :en,
        meta: %{
          "hreflang_alternates" => [
            {"en", "/articles/hello/"},
            {"tr", "/tr/articles/hello/"}
          ]
        }
      }

      assigns = %{site: @multi_lang_site, content: content, lang: :en}
      html = LanguageSwitcher.render(assigns)

      assert html =~ ~s(id="lang-switcher")
      assert html =~ ~s(id="lang-toggle")
      assert html =~ ~s(id="lang-menu")
      refute html =~ "-default"
    end

    test "render/1 with desktop variant generates desktop IDs" do
      content = %Content{
        title: "Hello",
        body: "<p>Hello</p>",
        slug: "hello",
        lang: :en,
        meta: %{
          "hreflang_alternates" => [
            {"en", "/articles/hello/"},
            {"tr", "/tr/articles/hello/"}
          ]
        }
      }

      assigns = %{site: @multi_lang_site, content: content, lang: :en, variant: :desktop}
      html = LanguageSwitcher.render(assigns)

      assert html =~ ~s(id="lang-switcher-desktop")
      assert html =~ ~s(id="lang-toggle-desktop")
      assert html =~ ~s(id="lang-menu-desktop")
    end
  end
end
