defmodule Sayfa.Markdown do
  @moduledoc """
  Wrapper around MDEx for rendering Markdown to HTML.

  Provides a consistent interface with `{:ok, html}` / `{:error, reason}`
  tuples and a bang variant that raises on error.

  Supports optional syntax highlighting theme selection via the `theme` parameter.

  ## Examples

      iex> {:ok, html} = Sayfa.Markdown.render("# Hello")
      iex> html =~ "Hello"
      true

      iex> Sayfa.Markdown.render!("**bold**")
      "<p><strong>bold</strong></p>"

  """

  @doc """
  Renders a Markdown string to HTML.

  Headings include anchor IDs for linking (e.g., `<h1 id="hello">...</h1>`).
  An optional `theme` string selects the syntax highlighting theme (default: `"github_light"`).

  ## Examples

      iex> {:ok, html} = Sayfa.Markdown.render("# Hello")
      iex> html =~ ~s(id="hello")
      true

      iex> Sayfa.Markdown.render("plain text")
      {:ok, "<p>plain text</p>"}

  """
  @spec render(String.t()) :: {:ok, String.t()} | {:error, term()}
  @spec render(String.t(), String.t()) :: {:ok, String.t()} | {:error, term()}
  def render(markdown, theme \\ "github_light") when is_binary(markdown) do
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
  @spec render!(String.t(), String.t()) :: String.t()
  def render!(markdown, theme \\ "github_light") when is_binary(markdown) do
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
        header_ids: ""
      ],
      render: [
        unsafe_: true
      ],
      syntax_highlight: [
        formatter: {:html_inline, theme: theme}
      ]
    ]
  end
end
