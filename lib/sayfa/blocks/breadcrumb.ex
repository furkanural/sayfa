defmodule Sayfa.Blocks.Breadcrumb do
  @moduledoc """
  Breadcrumb block with JSON-LD structured data.

  Renders a visible `<nav>` breadcrumb trail and a `<script type="application/ld+json">`
  tag with `BreadcrumbList` schema for SEO.

  The breadcrumb trail is derived from the content's `url_prefix` and `title`:

  - `/posts/hello/` → Home > Posts > Hello
  - `/about/` → Home > About
  - List/home pages (no `@content`) → no output

  ## Assigns

  - `:content` — current `Sayfa.Content` struct (nil on list/home pages)
  - `:site` — site config map with `:base_url`

  ## Examples

      <%= @block.(:breadcrumb, []) %>

  """

  @behaviour Sayfa.Behaviours.Block

  @impl true
  def name, do: :breadcrumb

  @impl true
  def render(assigns) do
    content = Map.get(assigns, :content)

    if content do
      site = Map.get(assigns, :site, %{})
      base_url = Map.get(site, :base_url, "") |> String.trim_trailing("/")
      crumbs = build_crumbs(content)

      render_html(crumbs) <> render_json_ld(crumbs, base_url)
    else
      ""
    end
  end

  defp build_crumbs(content) do
    url_prefix = content.meta["url_prefix"] || ""
    title = content.title || ""

    case url_prefix do
      "" ->
        [{title, nil}]

      prefix ->
        section_name = String.capitalize(prefix)
        [{section_name, "/#{prefix}/"}, {title, nil}]
    end
  end

  defp render_html(crumbs) do
    chevron =
      ~s(<svg class="w-3.5 h-3.5 text-slate-300 dark:text-slate-600 shrink-0" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="m9 18 6-6-6-6"/></svg>)

    items =
      Enum.map(crumbs, fn {name, url} ->
        escaped = Sayfa.Block.escape_html(name)

        content =
          if url do
            ~s(<a href="#{url}" class="text-slate-500 dark:text-slate-400 hover:text-primary dark:hover:text-primary-400">#{escaped}</a>)
          else
            escaped
          end

        ~s(#{chevron}<li class="text-slate-900 dark:text-slate-100">#{content}</li>)
      end)

    home_link =
      ~s(<li><a href="/" class="text-slate-500 dark:text-slate-400 hover:text-primary dark:hover:text-primary-400">Home</a></li>)

    ~s(<nav aria-label="Breadcrumb" class="mb-6"><ol class="flex items-center gap-1.5 text-sm text-slate-500 dark:text-slate-400">#{home_link}#{Enum.join(items)}</ol></nav>)
  end

  defp render_json_ld(crumbs, base_url) do
    all_crumbs = [{"Home", "/"} | crumbs]

    items =
      all_crumbs
      |> Enum.with_index(1)
      |> Enum.map(fn {{name, url}, position} ->
        escaped_name = json_escape(name)

        if url do
          ~s({"@type":"ListItem","position":#{position},"name":"#{escaped_name}","item":"#{base_url}#{url}"})
        else
          ~s({"@type":"ListItem","position":#{position},"name":"#{escaped_name}"})
        end
      end)

    ~s(<script type="application/ld+json">{"@context":"https://schema.org","@type":"BreadcrumbList","itemListElement":[#{Enum.join(items, ",")}]}</script>)
  end

  defp json_escape(str) do
    str
    |> String.replace("\\", "\\\\")
    |> String.replace("\"", "\\\"")
    |> String.replace("\n", "\\n")
  end
end
