defmodule Sayfa.ConfigTest do
  use ExUnit.Case, async: true

  alias Sayfa.Config

  describe "defaults/0" do
    test "returns default config map" do
      defaults = Config.defaults()
      assert defaults.title == "My Site"
      assert defaults.base_url == "http://localhost:4000"
      assert defaults.content_dir == "content"
      assert defaults.output_dir == "output"
      assert defaults.theme == "default"
      assert defaults.default_lang == :en
      assert defaults.drafts == false
      assert defaults.social_links == []
    end
  end

  describe "get/1 and get/2" do
    test "returns default value for known key" do
      assert Config.get(:title) == "My Site"
    end

    test "returns nil for unknown key" do
      assert Config.get(:nonexistent) == nil
    end

    test "returns custom default for unknown key" do
      assert Config.get(:nonexistent, "fallback") == "fallback"
    end

    test "reads from application env" do
      Application.put_env(:sayfa, :site, title: "Custom Title")
      assert Config.get(:title) == "Custom Title"
    after
      Application.delete_env(:sayfa, :site)
    end
  end

  describe "resolve/1" do
    test "returns defaults when no overrides" do
      config = Config.resolve([])
      assert config.title == "My Site"
      assert config.output_dir == "output"
    end

    test "runtime opts override defaults" do
      config = Config.resolve(title: "Override", content_dir: "custom")
      assert config.title == "Override"
      assert config.content_dir == "custom"
    end

    test "runtime opts override app env" do
      Application.put_env(:sayfa, :site, title: "From Env")
      config = Config.resolve(title: "From Opts")
      assert config.title == "From Opts"
    after
      Application.delete_env(:sayfa, :site)
    end

    test "app env overrides defaults" do
      Application.put_env(:sayfa, :site, title: "From Env")
      config = Config.resolve([])
      assert config.title == "From Env"
    after
      Application.delete_env(:sayfa, :site)
    end
  end

  describe "theme_layouts_dir/1" do
    test "returns priv path for default theme" do
      path = Config.theme_layouts_dir(%{theme: "default"})
      assert String.ends_with?(path, "default_theme/layouts")
    end

    test "returns themes path for custom theme" do
      path = Config.theme_layouts_dir(%{theme: "my_theme"})
      assert path == Path.join(["themes", "my_theme", "layouts"])
    end
  end

  describe "default_theme_path/1" do
    test "returns path under priv/default_theme" do
      path = Config.default_theme_path("layouts")
      assert String.ends_with?(path, "priv/default_theme/layouts")
    end
  end
end
