defmodule Sayfa.Block do
  @moduledoc """
  Registry and lookup functions for blocks.

  Maps block names to block modules. By default, nine built-in blocks
  are registered. Custom blocks can be added via application config:

      config :sayfa, :blocks, [MyApp.Blocks.Banner | Sayfa.Block.default_blocks()]

  ## Block Helper

  The `build_helper/1` function creates a closure that templates use as `@block`:

      block_fn = Sayfa.Block.build_helper(site: config, content: content, contents: all_contents, lang: :en)
      block_fn.(:hero, title: "Welcome")
      #=> "<section class=\\"hero\\">..."

  ## Examples

      iex> length(Sayfa.Block.default_blocks())
      9

      iex> Sayfa.Block.find_by_name(:hero)
      Sayfa.Blocks.Hero

      iex> Sayfa.Block.find_by_name(:nonexistent)
      nil

  """

  @doc """
  Returns the list of built-in block modules.

  ## Examples

      iex> length(Sayfa.Block.default_blocks())
      9

  """
  @spec default_blocks() :: [module()]
  def default_blocks do
    [
      Sayfa.Blocks.Hero,
      Sayfa.Blocks.Header,
      Sayfa.Blocks.Footer,
      Sayfa.Blocks.SocialLinks,
      Sayfa.Blocks.TOC,
      Sayfa.Blocks.RecentPosts,
      Sayfa.Blocks.TagCloud,
      Sayfa.Blocks.ReadingTime,
      Sayfa.Blocks.CodeCopy
    ]
  end

  @doc """
  Returns all registered block modules.

  Reads from application config, falling back to `default_blocks/0`.

  ## Examples

      iex> blocks = Sayfa.Block.all()
      iex> is_list(blocks)
      true

  """
  @spec all() :: [module()]
  def all do
    Application.get_env(:sayfa, :blocks, default_blocks())
  end

  @doc """
  Finds a block module by its atom name.

  ## Examples

      iex> Sayfa.Block.find_by_name(:hero)
      Sayfa.Blocks.Hero

      iex> Sayfa.Block.find_by_name(:nonexistent)
      nil

  """
  @spec find_by_name(atom()) :: module() | nil
  def find_by_name(name) do
    Enum.find(all(), fn mod -> mod.name() == name end)
  end

  @doc """
  Builds the `@block` helper function for templates.

  Takes a keyword list of context and returns a function that looks up
  a block by name, merges the context with caller options, and calls `render/1`.

  ## Context Keys

  - `:site` — resolved config map
  - `:content` — current `Sayfa.Content` struct (may be `nil`)
  - `:contents` — list of all site contents
  - `:lang` — current language atom

  ## Examples

      block_fn = Sayfa.Block.build_helper(site: config, content: content, contents: [], lang: :en)
      block_fn.(:hero, title: "Welcome")
      #=> "<section class=\\"hero\\">..."

      block_fn.(:nonexistent, [])
      #=> ""

  """
  @spec build_helper(keyword()) :: (atom(), keyword() -> String.t())
  def build_helper(context) do
    ctx_map = Map.new(context)

    fn name, opts ->
      case find_by_name(name) do
        nil ->
          ""

        mod ->
          assigns = Map.merge(ctx_map, Map.new(opts))
          mod.render(assigns)
      end
    end
  end

  @doc """
  Escapes HTML special characters in a string.

  ## Examples

      iex> Sayfa.Block.escape_html("<script>alert('xss')</script>")
      "&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;"

      iex> Sayfa.Block.escape_html("Hello & World")
      "Hello &amp; World"

  """
  @spec escape_html(String.t()) :: String.t()
  def escape_html(text) when is_binary(text) do
    text
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
    |> String.replace("'", "&#39;")
  end

  def escape_html(nil), do: ""
end
