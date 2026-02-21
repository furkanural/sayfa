defmodule Sayfa.Block do
  @moduledoc """
  Registry and lookup functions for blocks.

  Maps block names to block modules. By default, fifteen built-in blocks
  are registered. Custom blocks can be added via application config:

      config :sayfa, :blocks, [MyApp.Blocks.Banner | Sayfa.Block.default_blocks()]

  ## Block Helper

  The `build_helper/1` function creates a closure that templates use as `@block`:

      block_fn = Sayfa.Block.build_helper(site: config, content: content, contents: all_contents, lang: :en)
      block_fn.(:hero, title: "Welcome")
      #=> "<section class=\\"hero\\">..."

  ## Examples

      iex> length(Sayfa.Block.default_blocks())
      15

      iex> Sayfa.Block.find_by_name(:hero)
      Sayfa.Blocks.Hero

      iex> Sayfa.Block.find_by_name(:nonexistent)
      nil

  """

  @doc """
  Returns the list of built-in block modules.

  ## Examples

      iex> length(Sayfa.Block.default_blocks())
      15

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
      Sayfa.Blocks.CategoryCloud,
      Sayfa.Blocks.ReadingTime,
      Sayfa.Blocks.CodeCopy,
      Sayfa.Blocks.RecentContent,
      Sayfa.Blocks.Search,
      Sayfa.Blocks.CopyLink,
      Sayfa.Blocks.Breadcrumb,
      Sayfa.Blocks.LanguageSwitcher
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
  - `:t` — translation function `(String.t() -> String.t())`

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

  @doc """
  Returns an SVG icon for the given social platform label.

  ## Examples

      iex> Sayfa.Block.social_icon("github", "w-4 h-4") |> String.contains?("svg")
      true

      iex> Sayfa.Block.social_icon("unknown", "w-5 h-5") |> String.contains?("svg")
      true

  """
  @spec social_icon(String.t(), String.t()) :: String.t()
  def social_icon(label, size \\ "w-5 h-5") do
    case String.downcase(label) do
      "github" ->
        ~s(<svg class="#{size}" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24"><path d="M15 22v-4a4.8 4.8 0 0 0-1-3.5c3 0 6-2 6-5.5.08-1.25-.27-2.48-1-3.5.28-1.15.28-2.35 0-3.5 0 0-1 0-3 1.5-2.64-.5-5.36-.5-8 0C6 2 5 2 5 2c-.3 1.15-.3 2.35 0 3.5A5.403 5.403 0 0 0 4 9c0 3.5 3 5.5 6 5.5-.39.49-.68 1.05-.85 1.65-.17.6-.22 1.23-.15 1.85v4"/><path d="M9 18c-4.51 2-5-2-7-2"/></svg>)

      x when x in ["twitter", "x", "x / twitter"] ->
        ~s(<svg class="#{size}" fill="currentColor" stroke="none" viewBox="0 0 24 24"><path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z"/></svg>)

      "mastodon" ->
        ~s(<svg class="#{size}" fill="currentColor" stroke="none" viewBox="0 0 24 24"><path d="M21.327 8.566c0-4.339-2.843-5.61-2.843-5.61-1.433-.658-3.894-.935-6.451-.956h-.063c-2.557.021-5.016.298-6.45.956 0 0-2.843 1.272-2.843 5.61 0 .993-.019 2.181.012 3.441.103 4.243.778 8.425 4.701 9.463 1.809.479 3.362.579 4.612.51 2.268-.126 3.541-.809 3.541-.809l-.075-1.646s-1.621.511-3.441.449c-1.804-.062-3.707-.194-3.999-2.409a4.5 4.5 0 0 1-.04-.621s1.77.432 4.014.535c1.372.063 2.658-.08 3.965-.236 2.506-.299 4.688-1.843 4.962-3.254.434-2.223.398-5.424.398-5.424zm-3.353 5.59h-2.081V9.057c0-1.075-.452-1.62-1.357-1.62-1 0-1.501.647-1.501 1.927v2.791h-2.069V9.364c0-1.28-.501-1.927-1.502-1.927-.905 0-1.357.546-1.357 1.62v5.099H6.026V8.903c0-1.074.273-1.927.823-2.558.566-.631 1.307-.955 2.228-.955 1.065 0 1.872.41 2.405 1.228l.518.869.519-.869c.533-.818 1.34-1.228 2.405-1.228.92 0 1.662.324 2.228.955.549.631.822 1.484.822 2.558z"/></svg>)

      "goodreads" ->
        ~s(<svg class="#{size}" fill="currentColor" stroke="none" viewBox="0 0 24 24"><path d="M17.346.026c.422-.083.859.037 1.179.325.346.284.55.705.557 1.153-.023.457-.247.88-.612 1.156l-2.182 1.748a.601.601 0 0 0-.255.43.52.52 0 0 0 .11.424 5.886 5.886 0 0 1 .832 6.58c-1.394 2.79-4.503 3.99-7.501 2.927a.792.792 0 0 0-.499-.01c-.224.07-.303.18-.453.383l-.014.02-.941 1.254s-.792.985.457.935c3.027-.119 3.817-.119 5.439-.01 2.641.18 3.806 1.903 3.806 3.275 0 1.623-1.036 3.383-3.809 3.383a117.46 117.46 0 0 0-5.517-.03c-.31.005-.597.013-.835.02-.228.006-.41.011-.52.011-.712 0-1.648-.186-1.66-1.068-.008-.729.624-1.12 1.11-1.172.43-.045.815.007 1.24.064.252.034.518.07.815.088.185.011.366.025.552.038.53.038 1.102.08 1.926.087.427.005.759.01 1.025.015.695.012.941.016 1.28-.015 1.248-.112 1.832-.61 1.832-1.376 0-.805-.584-1.264-1.698-1.414-1.564-.213-2.33-.163-3.72-.074a87.66 87.66 0 0 1-1.669.095c-.608.029-2.449.026-2.682-1.492-.053-.416-.073-1.116.807-2.325l.75-1.003c.36-.49.582-.898.053-1.559 0 0-.39-.468-.52-.638-1.215-1.587-1.512-4.08-.448-6.114 1.577-3.011 5.4-4.26 8.37-2.581.253.143.438.203.655.163.201-.032.27-.167.363-.344.02-.04.042-.082.067-.126.004-.01.241-.465.535-1.028l.734-1.41a1.493 1.493 0 0 1 1.041-.785ZM9.193 13.243c1.854.903 3.912.208 5.254-2.47 1.352-2.699.827-5.11-1.041-6.023C10.918 3.537 8.81 5.831 8.017 7.41c-1.355 2.698-.717 4.886 1.147 5.818Z"/></svg>)

      "email" ->
        ~s(<svg class="#{size}" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24"><rect width="20" height="16" x="2" y="4" rx="2"/><path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7"/></svg>)

      x when x in ["rss", "feed"] ->
        ~s(<svg class="#{size}" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24"><path d="M4 11a9 9 0 0 1 9 9"/><path d="M4 4a16 16 0 0 1 16 16"/><circle cx="5" cy="19" r="1"/></svg>)

      _ ->
        ~s(<svg class="#{size}" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24"><path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"/><path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"/></svg>)
    end
  end

  @doc """
  Returns the `rel` attribute for a social link.

  Returns `"me noopener"` for Mastodon links and `"noopener"` for all others.

  ## Examples

      iex> Sayfa.Block.social_rel("Mastodon")
      "me noopener"

      iex> Sayfa.Block.social_rel("GitHub")
      "noopener"

  """
  @spec social_rel(String.t()) :: String.t()
  def social_rel(label) do
    if String.contains?(String.downcase(label), "mastodon"),
      do: "me noopener",
      else: "noopener"
  end
end
