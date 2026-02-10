defmodule Sayfa.Config do
  @moduledoc """
  Configuration handling for Sayfa sites.

  Provides functions to read site configuration with sensible defaults.
  Configuration is resolved from three layers (lowest to highest priority):

  1. Built-in defaults
  2. Application environment (`config :sayfa, :site, ...`)
  3. Runtime options passed to `resolve/1`

  ## Examples

      # Get a single config value
      Sayfa.Config.get(:title)
      #=> "My Site"

      # Get with a custom default
      Sayfa.Config.get(:missing_key, "fallback")
      #=> "fallback"

      # Resolve full config map
      config = Sayfa.Config.resolve(content_dir: "custom/content")
      config.content_dir
      #=> "custom/content"

  """

  @defaults %{
    title: "My Site",
    base_url: "http://localhost:4000",
    content_dir: "content",
    output_dir: "output",
    theme: "default",
    default_lang: :en,
    drafts: false,
    posts_per_page: 10,
    author: nil,
    description: ""
  }

  @doc """
  Returns the built-in default configuration map.

  ## Examples

      iex> defaults = Sayfa.Config.defaults()
      iex> defaults.title
      "My Site"

  """
  @spec defaults() :: map()
  def defaults, do: @defaults

  @doc """
  Gets a single configuration value.

  Looks up the key in application environment, falling back to built-in defaults.

  ## Examples

      iex> Sayfa.Config.get(:title)
      "My Site"

      iex> Sayfa.Config.get(:nonexistent, "default")
      "default"

  """
  @spec get(atom()) :: term()
  def get(key) do
    get(key, Map.get(@defaults, key))
  end

  @spec get(atom(), term()) :: term()
  def get(key, default) do
    site_config = Application.get_env(:sayfa, :site, [])

    case Keyword.fetch(site_config, key) do
      {:ok, value} -> value
      :error -> default
    end
  end

  @doc """
  Resolves a complete configuration map.

  Merges built-in defaults, application environment, and runtime options
  (in that priority order) into a single map.

  ## Examples

      iex> config = Sayfa.Config.resolve(title: "Custom Site")
      iex> config.title
      "Custom Site"

      iex> config = Sayfa.Config.resolve([])
      iex> config.output_dir
      "output"

  """
  @spec resolve(keyword()) :: map()
  def resolve(opts \\ []) do
    app_env = Application.get_env(:sayfa, :site, []) |> Map.new()
    runtime = Map.new(opts)

    @defaults
    |> Map.merge(app_env)
    |> Map.merge(runtime)
  end

  @doc """
  Returns the path to the layouts directory for the given config.

  For the default theme, returns the path inside Sayfa's `priv/` directory.
  For custom themes, returns `themes/<name>/layouts/` relative to the site root.

  ## Examples

      iex> config = %{theme: "default"}
      iex> path = Sayfa.Config.theme_layouts_dir(config)
      iex> String.ends_with?(path, "default_theme/layouts")
      true

  """
  @spec theme_layouts_dir(map()) :: String.t()
  def theme_layouts_dir(%{theme: "default"}) do
    default_theme_path("layouts")
  end

  def theme_layouts_dir(%{theme: theme}) do
    Path.join(["themes", theme, "layouts"])
  end

  @doc """
  Returns the absolute path to a file within the default theme.

  Uses `:code.priv_dir/1` to locate Sayfa's `priv/` directory.

  ## Examples

      iex> path = Sayfa.Config.default_theme_path("layouts")
      iex> String.ends_with?(path, "priv/default_theme/layouts")
      true

  """
  @spec default_theme_path(String.t()) :: String.t()
  def default_theme_path(subpath) do
    priv_dir =
      case :code.priv_dir(:sayfa) do
        {:error, :bad_name} ->
          # Fallback for dev/test when priv hasn't been compiled
          Path.join(File.cwd!(), "priv")

        dir ->
          List.to_string(dir)
      end

    Path.join([priv_dir, "default_theme", subpath])
  end
end
