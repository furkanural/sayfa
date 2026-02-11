defmodule Sayfa.I18nTest do
  use ExUnit.Case, async: true

  alias Sayfa.I18n

  @config %{
    default_lang: :en,
    languages: [en: [name: "English"], tr: [name: "Türkçe"]]
  }

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
      assert {:tr, "posts/2024/merhaba.md"} = I18n.detect_language("tr/posts/2024/merhaba.md", @config)
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
end
