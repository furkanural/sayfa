defmodule Sayfa.Template do
  @moduledoc """
  EEx template rendering with three-layer composition.

  Templates are rendered in three layers:

  1. **Content body** — Markdown already rendered to HTML (from `Sayfa.Content`)
  2. **Layout template** — Wraps content body (e.g., `post.html.eex`, `page.html.eex`)
  3. **Base template** — HTML shell (`<html>`, `<head>`, `<body>`), wraps layout output

  ## Layout Selection

  The layout is determined by (in priority order):
  1. Front matter `layout:` key
  2. Content type directory default (`posts/` → `post`, `pages/` → `page`)
  3. Fallback to `page`

  ## Examples

      # Render an EEx string
      {:ok, html} = Sayfa.Template.render_string("<h1><%= @title %></h1>", title: "Hello")

      # Full three-layer render
      {:ok, html} = Sayfa.Template.render_content(content, config: config)

  """

  @layout_from_content_type %{
    "posts" => "post",
    "pages" => "page",
    "notes" => "post",
    "projects" => "page",
    "talks" => "page"
  }

  @doc """
  Renders an EEx string with the given assigns.

  ## Examples

      iex> Sayfa.Template.render_string("Hello <%= @name %>", name: "World")
      {:ok, "Hello World"}

  """
  @spec render_string(String.t(), keyword()) :: {:ok, String.t()} | {:error, term()}
  def render_string(eex_string, assigns) when is_binary(eex_string) do
    {:ok, EEx.eval_string(eex_string, assigns: Map.new(assigns))}
  rescue
    e -> {:error, {:template_render_error, Exception.message(e)}}
  end

  @doc """
  Renders an EEx template file with the given assigns.

  ## Examples

      Sayfa.Template.render_file("priv/default_theme/layouts/page.html.eex",
        inner_content: "<p>Hello</p>",
        content: content,
        site: config
      )

  """
  @spec render_file(String.t(), keyword()) :: {:ok, String.t()} | {:error, term()}
  def render_file(template_path, assigns) do
    {:ok, EEx.eval_file(template_path, assigns: Map.new(assigns))}
  rescue
    e -> {:error, {:template_render_error, template_path, Exception.message(e)}}
  end

  @doc """
  Renders content through the full three-layer template pipeline.

  1. Determines the layout from content metadata or content type
  2. Renders the layout template with content body as `@inner_content`
  3. Wraps the result in the base template

  ## Options

  - `:config` — resolved config map (required)
  - `:layouts_dir` — override layouts directory (optional, derived from config)

  ## Examples

      config = Sayfa.Config.resolve([])
      {:ok, html} = Sayfa.Template.render_content(content, config: config)

  """
  @spec render_content(Sayfa.Content.t(), keyword()) :: {:ok, String.t()} | {:error, term()}
  def render_content(%Sayfa.Content{} = content, opts) do
    config = Keyword.fetch!(opts, :config)
    all_contents = Keyword.get(opts, :all_contents, [])
    lang = content.lang || config.default_lang

    block_fn =
      Sayfa.Block.build_helper(
        site: config,
        content: content,
        contents: all_contents,
        lang: lang
      )

    layout_name = resolve_layout(content)

    layout_path =
      case Keyword.get(opts, :layouts_dir) do
        nil ->
          Sayfa.Theme.resolve_layout(layout_name, config) ||
            Sayfa.Theme.resolve_layout("page", config)

        dir ->
          path = Path.join(dir, "#{layout_name}.html.eex")
          if File.exists?(path), do: path, else: Path.join(dir, "page.html.eex")
      end

    base_path =
      case Keyword.get(opts, :layouts_dir) do
        nil -> Sayfa.Theme.resolve_layout("base", config)
        dir -> Path.join(dir, "base.html.eex")
      end

    base_assigns = [
      site: config,
      content: content,
      page_title: content.title,
      lang: lang,
      block: block_fn
    ]

    with {:ok, layout_html} <-
           render_file(layout_path, [inner_content: content.body] ++ base_assigns),
         {:ok, full_html} <-
           render_file(base_path, [inner_content: layout_html] ++ base_assigns) do
      {:ok, full_html}
    end
  end

  @doc """
  Renders a list page through the three-layer template pipeline.

  Used for archive pages (tags, categories) and content type index pages.
  Uses the `list.html.eex` layout with `@contents` and `@pagination` assigns.

  ## Options

  - `:config` — resolved config map (required)
  - `:layouts_dir` — override layouts directory (optional)
  - `:contents` — list of content items to display (required)
  - `:page_title` — title for the page (required)
  - `:pagination` — pagination struct (optional, nil for non-paginated)

  """
  @spec render_list_page(keyword()) :: {:ok, String.t()} | {:error, term()}
  def render_list_page(opts) do
    config = Keyword.fetch!(opts, :config)
    contents = Keyword.fetch!(opts, :contents)
    page_title = Keyword.fetch!(opts, :page_title)
    pagination = Keyword.get(opts, :pagination)
    all_contents = Keyword.get(opts, :all_contents, [])

    block_fn =
      Sayfa.Block.build_helper(
        site: config,
        content: nil,
        contents: all_contents,
        lang: config.default_lang
      )

    list_path =
      case Keyword.get(opts, :layouts_dir) do
        nil -> Sayfa.Theme.resolve_layout("list", config)
        dir -> Path.join(dir, "list.html.eex")
      end

    base_path =
      case Keyword.get(opts, :layouts_dir) do
        nil -> Sayfa.Theme.resolve_layout("base", config)
        dir -> Path.join(dir, "base.html.eex")
      end

    list_assigns = [
      contents: contents,
      pagination: pagination,
      page_title: page_title,
      site: config,
      content: nil,
      lang: config.default_lang,
      block: block_fn
    ]

    with {:ok, list_html} <- render_file(list_path, list_assigns),
         {:ok, full_html} <-
           render_file(base_path, [inner_content: list_html] ++ list_assigns) do
      {:ok, full_html}
    end
  end

  defp resolve_layout(%Sayfa.Content{meta: %{"layout" => layout}}) when is_binary(layout) do
    layout
  end

  defp resolve_layout(%Sayfa.Content{meta: %{"default_layout" => layout}}) when is_binary(layout) do
    layout
  end

  defp resolve_layout(%Sayfa.Content{meta: %{"content_type" => ct}}) do
    Map.get(@layout_from_content_type, ct, "page")
  end

  defp resolve_layout(_content), do: "page"
end
