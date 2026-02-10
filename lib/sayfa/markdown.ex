defmodule Sayfa.Markdown do
  @moduledoc """
  Wrapper around MDEx for rendering Markdown to HTML.

  Provides a consistent interface with `{:ok, html}` / `{:error, reason}`
  tuples and a bang variant that raises on error.

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

  ## Examples

      iex> {:ok, html} = Sayfa.Markdown.render("# Hello")
      iex> html =~ ~s(id="hello")
      true

      iex> Sayfa.Markdown.render("plain text")
      {:ok, "<p>plain text</p>"}

  """
  @spec render(String.t()) :: {:ok, String.t()} | {:error, term()}
  def render(markdown) when is_binary(markdown) do
    MDEx.to_html(markdown, opts())
  end

  @doc """
  Renders a Markdown string to HTML, raising on error.

  ## Examples

      iex> html = Sayfa.Markdown.render!("# Hello")
      iex> html =~ ~s(id="hello")
      true

  """
  @spec render!(String.t()) :: String.t()
  def render!(markdown) when is_binary(markdown) do
    case render(markdown) do
      {:ok, html} -> html
      {:error, reason} -> raise "Markdown rendering failed: #{inspect(reason)}"
    end
  end

  defp opts do
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
      ]
    ]
  end
end
