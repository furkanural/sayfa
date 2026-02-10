defmodule Sayfa.Markdown do
  @moduledoc """
  Wrapper around MDEx for rendering Markdown to HTML.

  Provides a consistent interface with `{:ok, html}` / `{:error, reason}`
  tuples and a bang variant that raises on error.

  ## Examples

      iex> Sayfa.Markdown.render("# Hello")
      {:ok, "<h1>Hello</h1>"}

      iex> Sayfa.Markdown.render!("**bold**")
      "<p><strong>bold</strong></p>"

  """

  @doc """
  Renders a Markdown string to HTML.

  ## Examples

      iex> Sayfa.Markdown.render("# Hello")
      {:ok, "<h1>Hello</h1>"}

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

      iex> Sayfa.Markdown.render!("# Hello")
      "<h1>Hello</h1>"

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
        tasklist: true
      ],
      render: [
        unsafe_: true
      ]
    ]
  end
end
