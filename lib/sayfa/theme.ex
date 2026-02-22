defmodule Sayfa.Theme do
  @moduledoc """
  Theme loading and layout resolution with inheritance.

  A theme is a directory under `themes/` containing layouts and optional static
  assets. Themes can inherit from a parent (defaulting to `"default"`).

  Layout resolution walks the inheritance chain: custom theme -> parent -> default.

  ## Theme Directory Structure

      themes/my_theme/
      ├── layouts/
      │   ├── post.html.eex
      │   └── custom.html.eex
      └── assets/
          ├── css/
          └── images/

  ## Configuration

      config :sayfa, :site,
        theme: "my_theme",
        theme_parent: "default"

  ## Examples

      config = Sayfa.Config.resolve(theme: "my_theme")
      dirs = Sayfa.Theme.resolve_layouts_dirs(config)
      #=> ["themes/my_theme/layouts", ".../priv/default_theme/layouts"]

  """

  @doc """
  Returns an ordered list of layout directories for the theme chain.

  Walks from the current theme through its parent(s) to the default theme.
  Only directories that exist are included.

  ## Examples

      iex> config = %{theme: "default", theme_parent: "default"}
      iex> dirs = Sayfa.Theme.resolve_layouts_dirs(config)
      iex> length(dirs) >= 1
      true

  """
  @spec resolve_layouts_dirs(map()) :: [String.t()]
  def resolve_layouts_dirs(config) do
    chain = theme_chain(config)

    chain
    |> Enum.map(&layouts_dir_for/1)
    |> Enum.filter(&File.dir?/1)
    |> Enum.uniq()
  end

  @doc """
  Finds the first existing layout file by walking the theme chain.

  Returns the path to the layout file, or `nil` if not found in any theme.

  ## Examples

      iex> config = %{theme: "default", theme_parent: "default"}
      iex> path = Sayfa.Theme.resolve_layout("base", config)
      iex> String.ends_with?(path, "base.html.eex")
      true

      iex> config = %{theme: "default", theme_parent: "default"}
      iex> Sayfa.Theme.resolve_layout("nonexistent_layout_xyz", config)
      nil

  """
  @spec resolve_layout(String.t(), map()) :: String.t() | nil
  def resolve_layout(layout_name, config) do
    filename = "#{layout_name}.html.eex"

    config
    |> resolve_layouts_dirs()
    |> Enum.map(&Path.join(&1, filename))
    |> Enum.find(&File.exists?/1)
  end

  @doc """
  Copies theme assets to the output directory.

  Copies files from `themes/<name>/assets/` to `<output_dir>/assets/`.
  Does nothing if the theme has no assets directory.

  ## Examples

      Sayfa.Theme.copy_assets(config, "output")

  """
  @spec copy_assets(map(), String.t()) :: :ok
  def copy_assets(config, output_dir) do
    chain = theme_chain(config)

    # Copy in reverse order so custom theme assets override parent's
    chain
    |> Enum.reverse()
    |> Enum.each(fn theme_name ->
      assets_dir = assets_dir_for(theme_name)

      if File.dir?(assets_dir) do
        dest = Path.join(output_dir, "assets")
        File.mkdir_p!(dest)
        copy_dir_recursive(assets_dir, dest)
      end
    end)

    :ok
  end

  # --- Private ---

  defp theme_chain(config) do
    theme = Map.get(config, :theme, "default")
    parent = Map.get(config, :theme_parent, "default")

    cond do
      theme == "default" ->
        ["default"]

      parent == "default" || parent == theme ->
        [theme, "default"]

      true ->
        [theme, parent, "default"]
    end
    |> Enum.uniq()
  end

  defp layouts_dir_for("default") do
    Sayfa.Config.default_theme_path("layouts")
  end

  defp layouts_dir_for(theme_name) do
    Path.join(["themes", theme_name, "layouts"])
  end

  defp assets_dir_for("default") do
    Sayfa.Config.default_theme_path("assets")
  end

  defp assets_dir_for(theme_name) do
    Path.join(["themes", theme_name, "assets"])
  end

  defp copy_dir_recursive(source, dest) do
    source
    |> Path.join("**/*")
    |> Path.wildcard()
    |> Enum.each(fn src_path ->
      relative = Path.relative_to(src_path, source)
      copy_asset_file(src_path, relative, dest)
    end)
  end

  defp copy_asset_file(src_path, relative, dest) when is_binary(src_path) do
    cond do
      File.dir?(src_path) ->
        File.mkdir_p!(Path.join(dest, relative))

      String.ends_with?(src_path, ".min.js") ->
        # Copy .min.js as the original .js filename
        dest_relative = String.replace_suffix(relative, ".min.js", ".js")
        copy_file!(src_path, Path.join(dest, dest_relative))

      String.ends_with?(src_path, ".js") &&
          File.exists?(String.replace_suffix(src_path, ".js", ".min.js")) ->
        # Skip .js when a .min.js variant exists alongside it
        :skip

      true ->
        copy_file!(src_path, Path.join(dest, relative))
    end
  end

  defp copy_file!(src_path, dest_path) do
    File.mkdir_p!(Path.dirname(dest_path))
    File.cp!(src_path, dest_path)
  end
end
