defmodule Sayfa.Markdown do
  @moduledoc """
  Wrapper around MDEx for rendering Markdown to HTML.

  Provides a consistent interface with `{:ok, html}` / `{:error, reason}`
  tuples and a bang variant that raises on error.

  Supports optional syntax highlighting theme selection via the `theme` parameter.

  Code blocks are highlighted for both light and dark color schemes at once
  using Lumis' `:html_multi_themes` formatter, so the colors automatically
  follow the reader's `color-scheme` via the CSS `light-dark()` function.

  ## Examples

      iex> {:ok, html} = Sayfa.Markdown.render("# Hello")
      iex> html =~ "Hello"
      true

      iex> Sayfa.Markdown.render!("**bold**")
      "<p><strong>bold</strong></p>"

  """

  @default_theme [light: "catppuccin_latte", dark: "catppuccin_mocha"]

  @typedoc """
  Syntax highlighting theme selection.

  Either a single theme name applied to both color schemes, or a keyword list
  (or map) with `:light` and `:dark` theme names.
  """
  @type theme :: String.t() | keyword(String.t()) | %{optional(atom()) => String.t()}

  @doc """
  Renders a Markdown string to HTML.

  Headings include anchor IDs for linking (e.g., `<h1 id="hello">...</h1>`).
  The optional `theme` selects the syntax highlighting themes. It accepts either
  a single theme name (applied to both schemes) or a `[light: ..., dark: ...]`
  pair (default: `[light: "catppuccin_latte", dark: "catppuccin_mocha"]`).

  ## Examples

      iex> {:ok, html} = Sayfa.Markdown.render("# Hello")
      iex> html =~ ~s(id="hello")
      true

      iex> Sayfa.Markdown.render("plain text")
      {:ok, "<p>plain text</p>"}

  """
  @spec render(String.t()) :: {:ok, String.t()} | {:error, term()}
  @spec render(String.t(), theme()) :: {:ok, String.t()} | {:error, term()}
  def render(markdown, theme \\ @default_theme) when is_binary(markdown) do
    MDEx.to_html(markdown, opts(theme))
  end

  @doc """
  Renders a Markdown string to HTML, raising on error.

  ## Examples

      iex> html = Sayfa.Markdown.render!("# Hello")
      iex> html =~ ~s(id="hello")
      true

  """
  @spec render!(String.t()) :: String.t()
  @spec render!(String.t(), theme()) :: String.t()
  def render!(markdown, theme \\ @default_theme) when is_binary(markdown) do
    case render(markdown, theme) do
      {:ok, html} -> html
      {:error, reason} -> raise "Markdown rendering failed: #{inspect(reason)}"
    end
  end

  defp opts(theme) do
    [
      extension: [
        strikethrough: true,
        table: true,
        autolink: true,
        tasklist: true,
        header_id_prefix: ""
      ],
      render: [
        unsafe_: true
      ],
      syntax_highlight: [
        engine: :lumis,
        opts: [
          formatter: {:html_multi_themes, themes: themes(theme), default_theme: "light-dark()"}
        ]
      ]
    ]
  end

  # Normalizes the theme argument into a `[light: ..., dark: ...]` keyword list.
  # A single theme name is applied to both color schemes.
  defp themes(theme) when is_binary(theme), do: [light: theme, dark: theme]

  defp themes(theme) when is_list(theme) or is_map(theme) do
    light = fetch_theme(theme, :light)
    dark = fetch_theme(theme, :dark)
    [light: light, dark: dark || light]
  end

  defp fetch_theme(theme, key) when is_list(theme), do: Keyword.get(theme, key)
  defp fetch_theme(theme, key) when is_map(theme), do: Map.get(theme, key)
end
