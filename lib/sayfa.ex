defmodule Sayfa do
  @moduledoc """
  Sayfa — a simple, extensible static site generator built in Elixir.

  Sayfa (Turkish for "page") provides core SSG functionality as a reusable
  Hex package. Users create their own sites by depending on Sayfa and
  writing content in Markdown with YAML front matter.

  ## Quick Start

      # Parse a markdown string with front matter
      {:ok, content} = Sayfa.parse("---\\ntitle: Hello\\n---\\n# World")
      content.title  #=> "Hello"
      content.body   #=> "<h1>...World</h1>"  # includes anchor id

      # Parse a file
      {:ok, content} = Sayfa.parse_file("content/posts/hello.md")

      # Render markdown to HTML
      {:ok, html} = Sayfa.render_markdown("# Hello **World**")

  """

  @doc """
  Parses a raw string containing YAML front matter and Markdown body.

  See `Sayfa.Content.parse/1` for details.
  """
  @spec parse(String.t()) :: {:ok, Sayfa.Content.t()} | {:error, term()}
  defdelegate parse(raw_string), to: Sayfa.Content

  @doc """
  Reads and parses a content file from disk.

  See `Sayfa.Content.parse_file/1` for details.
  """
  @spec parse_file(String.t()) :: {:ok, Sayfa.Content.t()} | {:error, term()}
  defdelegate parse_file(file_path), to: Sayfa.Content

  @doc """
  Renders a Markdown string to HTML.

  See `Sayfa.Markdown.render/1` for details.
  """
  @spec render_markdown(String.t()) :: {:ok, String.t()} | {:error, term()}
  defdelegate render_markdown(markdown), to: Sayfa.Markdown, as: :render

  @doc """
  Builds the static site from content files.

  See `Sayfa.Builder.build/1` for details and options.
  """
  @spec build(keyword()) :: {:ok, Sayfa.Builder.Result.t()} | {:error, term()}
  defdelegate build(opts \\ []), to: Sayfa.Builder

  @doc """
  Removes the output directory.

  See `Sayfa.Builder.clean/1` for details.
  """
  @spec clean(keyword()) :: :ok
  defdelegate clean(opts \\ []), to: Sayfa.Builder
end
