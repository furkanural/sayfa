defmodule Sayfa.I18nTest do
  use ExUnit.Case, async: false

  alias Sayfa.I18n

  @config %{
    default_lang: :en,
    languages: [en: [name: "English"], tr: [name: "Türkçe"]]
  }

  setup do
    I18n.clear_cache()
    :ok
  end

  describe "detect_language/2" do
    test "detects non-default language from path" do
      assert {:tr, "posts/merhaba.md"} = I18n.detect_language("tr/posts/merhaba.md", @config)
    end

    test "returns default language for default-language content" do
      assert {:en, "posts/hello.md"} = I18n.detect_language("posts/hello.md", @config)
    end

    test "returns default language for root-level files" do
      assert {:en, "about.md"} = I18n.detect_language("about.md", @config)
    end

    test "does not detect unconfigured language" do
      assert {:en, "fr/posts/bonjour.md"} = I18n.detect_language("fr/posts/bonjour.md", @config)
    end

    test "does not treat default language subdirectory as language prefix" do
      assert {:en, "en/posts/hello.md"} = I18n.detect_language("en/posts/hello.md", @config)
    end

    test "handles deeply nested paths" do
      assert {:tr, "posts/2024/merhaba.md"} =
               I18n.detect_language("tr/posts/2024/merhaba.md", @config)
    end
  end

  describe "language_prefix/2" do
    test "returns empty string for default language" do
      assert "" == I18n.language_prefix(:en, @config)
    end

    test "returns language code for non-default language" do
      assert "tr" == I18n.language_prefix(:tr, @config)
    end
  end

  describe "configured_language_codes/1" do
    test "returns all configured language codes" do
      assert [:en, :tr] = I18n.configured_language_codes(@config)
    end

    test "returns default when no languages configured" do
      config = %{languages: [en: [name: "English"]]}
      assert [:en] = I18n.configured_language_codes(config)
    end
  end

  describe "t/3" do
    test "returns language-specific translation" do
      config = %{
        default_lang: :en,
        languages: [
          en: [name: "English"],
          tr: [name: "Türkçe", translations: %{"next" => "Sonraki"}]
        ]
      }

      assert "Sonraki" == I18n.t("next", :tr, config)
    end

    test "falls back to default language translation" do
      config = %{
        default_lang: :en,
        languages: [
          en: [name: "English", translations: %{"next" => "Forward"}],
          tr: [name: "Türkçe"]
        ]
      }

      assert "Forward" == I18n.t("next", :tr, config)
    end

    test "falls back to YAML translations when no config translations" do
      config = %{default_lang: :en, languages: [en: [name: "English"]]}

      assert "Next" == I18n.t("next", :en, config)
      assert "Previous" == I18n.t("previous", :en, config)
      # min_read is now a plural map; without count it returns the "other" form
      assert "%{count} min read" == I18n.t("min_read", :en, config)
    end

    test "falls back to YAML translations for non-default language" do
      config = %{
        default_lang: :en,
        languages: [en: [name: "English"], tr: [name: "Türkçe"]]
      }

      assert "Sonraki" == I18n.t("next", :tr, config)
      assert "Önceki" == I18n.t("previous", :tr, config)
    end

    test "falls back to default lang YAML when requested lang has no YAML" do
      config = %{
        default_lang: :en,
        languages: [en: [name: "English"], xx: [name: "Unknown"]]
      }

      assert "Next" == I18n.t("next", :xx, config)
    end

    test "falls back to key itself for unknown keys" do
      config = %{default_lang: :en, languages: [en: [name: "English"]]}

      assert "unknown_key" == I18n.t("unknown_key", :en, config)
    end

    test "language-specific config overrides YAML translation" do
      config = %{
        default_lang: :en,
        languages: [
          en: [name: "English", translations: %{"next" => "Go Forward"}]
        ]
      }

      assert "Go Forward" == I18n.t("next", :en, config)
    end
  end

  describe "t/4 with bindings" do
    test "interpolates count into plural form" do
      config = %{default_lang: :en, languages: [en: [name: "English"]]}

      assert "5 min read" == I18n.t("min_read", :en, config, count: 5)
    end

    test "selects singular form when count is 1" do
      config = %{default_lang: :en, languages: [en: [name: "English"]]}

      assert "1 post" == I18n.t("posts_count", :en, config, count: 1)
    end

    test "selects plural form when count is not 1" do
      config = %{default_lang: :en, languages: [en: [name: "English"]]}

      assert "5 posts" == I18n.t("posts_count", :en, config, count: 5)
    end

    test "interpolates count into Turkish translations" do
      config = %{default_lang: :en, languages: [en: [name: "English"], tr: [name: "Türkçe"]]}

      assert "3 dk okuma" == I18n.t("min_read", :tr, config, count: 3)
    end

    test "interpolates arbitrary bindings" do
      config = %{
        default_lang: :en,
        languages: [en: [name: "English", translations: %{"greeting" => "Hello %{name}!"}]]
      }

      assert "Hello World!" == I18n.t("greeting", :en, config, name: "World")
    end

    test "returns other form without interpolation when no bindings" do
      config = %{default_lang: :en, languages: [en: [name: "English"]]}

      # Without count binding, returns raw "other" form
      assert "%{count} min read" == I18n.t("min_read", :en, config)
    end
  end

  describe "translate_function/2" do
    test "returns a closure that translates keys" do
      config = %{
        default_lang: :en,
        languages: [
          en: [name: "English"],
          tr: [name: "Türkçe", translations: %{"next" => "Sonraki", "previous" => "Önceki"}]
        ]
      }

      t = I18n.translate_function(:tr, config)

      assert "Sonraki" == t.("next")
      assert "Önceki" == t.("previous")
      # Falls through to YAML for untranslated keys
      assert "Ana Sayfa" == t.("home")
    end
  end

  describe "default_translate_function/0" do
    test "returns English YAML translations" do
      t = I18n.default_translate_function()

      assert "Next" == t.("next")
      assert "Previous" == t.("previous")
      assert "Home" == t.("home")
    end

    test "returns key for unknown keys" do
      t = I18n.default_translate_function()

      assert "nonexistent" == t.("nonexistent")
    end
  end

  describe "load_translations/1" do
    test "loads English translations from YAML" do
      translations = I18n.load_translations(:en)

      assert "Next" == Map.get(translations, "next")
      assert "Previous" == Map.get(translations, "previous")
      # min_read uses %{count} interpolation (plain string since one/other are identical)
      assert "%{count} min read" == Map.get(translations, "min_read")
    end

    test "loads Turkish translations from YAML" do
      translations = I18n.load_translations(:tr)

      assert "Sonraki" == Map.get(translations, "next")
      assert "%{count} dk okuma" == Map.get(translations, "min_read")
    end

    test "returns empty map for unknown language" do
      translations = I18n.load_translations(:xx)

      assert %{} == translations
    end

    test "caches translations in persistent_term" do
      # First call loads from file
      translations1 = I18n.load_translations(:en)
      # Second call should return cached value
      translations2 = I18n.load_translations(:en)

      assert translations1 == translations2
    end
  end

  describe "clear_cache/0" do
    test "clears cached translations" do
      # Load to populate cache
      I18n.load_translations(:en)
      assert :persistent_term.get({I18n, :translations, :en}, :not_loaded) != :not_loaded

      # Clear cache
      I18n.clear_cache()
      assert :persistent_term.get({I18n, :translations, :en}, :not_loaded) == :not_loaded
    end
  end

  describe "rtl_language?/1" do
    test "returns true for Arabic" do
      assert I18n.rtl_language?(:ar)
    end

    test "returns true for Hebrew" do
      assert I18n.rtl_language?(:he)
    end

    test "returns true for Farsi" do
      assert I18n.rtl_language?(:fa)
    end

    test "returns true for Urdu" do
      assert I18n.rtl_language?(:ur)
    end

    test "returns false for English" do
      refute I18n.rtl_language?(:en)
    end

    test "returns false for Turkish" do
      refute I18n.rtl_language?(:tr)
    end
  end

  describe "text_direction/1" do
    test "returns rtl for Arabic" do
      assert "rtl" == I18n.text_direction(:ar)
    end

    test "returns ltr for English" do
      assert "ltr" == I18n.text_direction(:en)
    end

    test "returns rtl for Hebrew" do
      assert "rtl" == I18n.text_direction(:he)
    end

    test "returns ltr for Turkish" do
      assert "ltr" == I18n.text_direction(:tr)
    end
  end

  describe "resolve_site_config/3" do
    test "merges language-specific overrides onto base config" do
      config = %{
        title: "My Blog",
        description: "A blog",
        default_lang: :en,
        languages: [
          en: [name: "English"],
          tr: [name: "Türkçe", title: "Blogum", description: "Bir blog"]
        ]
      }

      resolved = I18n.resolve_site_config(config, :tr, config)

      assert "Blogum" == resolved.title
      assert "Bir blog" == resolved.description
    end

    test "returns base config for default language without overrides" do
      config = %{
        title: "My Blog",
        default_lang: :en,
        languages: [en: [name: "English"]]
      }

      resolved = I18n.resolve_site_config(config, :en, config)

      assert "My Blog" == resolved.title
    end

    test "excludes :name and :translations from overrides" do
      config = %{
        title: "My Blog",
        default_lang: :en,
        languages: [
          tr: [
            name: "Türkçe",
            translations: %{"next" => "Sonraki"},
            title: "Blogum"
          ]
        ]
      }

      resolved = I18n.resolve_site_config(config, :tr, config)

      assert "Blogum" == resolved.title
      refute Map.has_key?(resolved, :name)
      refute Map.has_key?(resolved, :translations)
    end

    test "language nav overrides base nav" do
      config = %{
        title: "My Blog",
        default_lang: :en,
        nav: [{"Home", "/"}, {"Posts", "/posts/"}],
        languages: [
          en: [name: "English"],
          tr: [
            name: "Türkçe",
            nav: [{"Ana Sayfa", "/"}, {"Yazılar", "/tr/posts/"}]
          ]
        ]
      }

      resolved = I18n.resolve_site_config(config, :tr, config)

      assert [{"Ana Sayfa", "/"}, {"Yazılar", "/tr/posts/"}] == resolved.nav
    end
  end
end
