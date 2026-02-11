defmodule Sayfa.ThemeTest do
  use ExUnit.Case, async: true

  alias Sayfa.Theme

  setup do
    tmp_dir = Path.join(System.tmp_dir!(), "sayfa_theme_#{System.unique_integer([:positive])}")
    File.mkdir_p!(tmp_dir)
    on_exit(fn -> File.rm_rf!(tmp_dir) end)
    {:ok, tmp_dir: tmp_dir}
  end

  describe "resolve_layouts_dirs/1" do
    test "returns default theme layouts dir for default theme" do
      config = %{theme: "default", theme_parent: "default"}
      dirs = Theme.resolve_layouts_dirs(config)

      assert length(dirs) == 1
      assert hd(dirs) |> String.ends_with?("default_theme/layouts")
    end

    test "returns custom + default dirs for custom theme", ctx do
      original_dir = File.cwd!()
      File.cd!(ctx.tmp_dir)

      custom_layouts = Path.join(["themes", "my_theme", "layouts"])
      File.mkdir_p!(custom_layouts)

      config = %{theme: "my_theme", theme_parent: "default"}
      dirs = Theme.resolve_layouts_dirs(config)

      assert length(dirs) == 2
      assert Enum.any?(dirs, &String.contains?(&1, "my_theme"))
      assert Enum.any?(dirs, &String.contains?(&1, "default_theme"))

      File.cd!(original_dir)
    end
  end

  describe "resolve_layout/2" do
    test "finds layout in default theme" do
      config = %{theme: "default", theme_parent: "default"}
      path = Theme.resolve_layout("base", config)

      assert path != nil
      assert String.ends_with?(path, "base.html.eex")
      assert File.exists?(path)
    end

    test "finds all default layouts" do
      config = %{theme: "default", theme_parent: "default"}

      for layout <- ~w(base post page list home) do
        path = Theme.resolve_layout(layout, config)
        assert path != nil, "Expected to find layout: #{layout}"
        assert File.exists?(path)
      end
    end

    test "returns nil for nonexistent layout" do
      config = %{theme: "default", theme_parent: "default"}
      assert Theme.resolve_layout("nonexistent_layout_xyz", config) == nil
    end

    test "custom theme layout overrides default", ctx do
      # Create a custom theme with a page layout
      custom_layouts = Path.join([ctx.tmp_dir, "custom_theme", "layouts"])
      File.mkdir_p!(custom_layouts)
      File.write!(Path.join(custom_layouts, "page.html.eex"), "<custom><%= @inner_content %></custom>")

      # We need to work in the tmp_dir context
      original_dir = File.cwd!()
      File.cd!(ctx.tmp_dir)

      # Create themes/custom_theme/layouts in CWD
      theme_layouts = Path.join(["themes", "custom_theme", "layouts"])
      File.mkdir_p!(theme_layouts)
      File.write!(Path.join(theme_layouts, "page.html.eex"), "<custom><%= @inner_content %></custom>")

      config = %{theme: "custom_theme", theme_parent: "default"}
      path = Theme.resolve_layout("page", config)

      assert path != nil
      assert String.contains?(path, "custom_theme")
      assert File.read!(path) =~ "<custom>"

      File.cd!(original_dir)
    end

    test "falls back to default when custom theme missing layout", ctx do
      original_dir = File.cwd!()
      File.cd!(ctx.tmp_dir)

      # Create theme dir with only one layout
      theme_layouts = Path.join(["themes", "sparse_theme", "layouts"])
      File.mkdir_p!(theme_layouts)
      File.write!(Path.join(theme_layouts, "custom.html.eex"), "<custom/>")

      config = %{theme: "sparse_theme", theme_parent: "default"}

      # "base" doesn't exist in sparse_theme, should fall back to default
      path = Theme.resolve_layout("base", config)
      assert path != nil
      assert String.contains?(path, "default_theme")

      # "custom" exists in sparse_theme
      custom_path = Theme.resolve_layout("custom", config)
      assert custom_path != nil
      assert String.contains?(custom_path, "sparse_theme")

      File.cd!(original_dir)
    end
  end

  describe "copy_assets/2" do
    test "copies theme assets to output dir", ctx do
      original_dir = File.cwd!()
      File.cd!(ctx.tmp_dir)

      # Create theme with assets
      assets_dir = Path.join(["themes", "my_theme", "assets", "css"])
      File.mkdir_p!(assets_dir)
      File.write!(Path.join(assets_dir, "style.css"), "body { color: red; }")

      output_dir = Path.join(ctx.tmp_dir, "output")
      config = %{theme: "my_theme", theme_parent: "default"}

      Theme.copy_assets(config, output_dir)

      assert File.exists?(Path.join([output_dir, "assets", "css", "style.css"]))
      assert File.read!(Path.join([output_dir, "assets", "css", "style.css"])) == "body { color: red; }"

      File.cd!(original_dir)
    end

    test "does nothing when theme has no assets", ctx do
      output_dir = Path.join(ctx.tmp_dir, "output")
      config = %{theme: "default", theme_parent: "default"}

      assert :ok = Theme.copy_assets(config, output_dir)
    end
  end
end
