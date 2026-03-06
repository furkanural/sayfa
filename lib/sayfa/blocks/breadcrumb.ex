defmodule Sayfa.Blocks.Breadcrumb do
  @moduledoc """
  Back-link block with JSON-LD structured data.

  Renders a minimal `← Section` back link for section content (e.g. articles,
  notes) and a `<script type="application/ld+json">` tag with `BreadcrumbList`
  schema for SEO. Bare pages (no `url_prefix`) emit only the JSON-LD.

  - `/articles/hello/` → renders `← Articles` back link
  - `/about/` → no back link (JSON-LD only)
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
      t = Map.get(assigns, :t, Sayfa.I18n.default_translate_function())
      base_url = Map.get(site, :base_url, "") |> String.trim_trailing("/")
      crumbs = build_crumbs(content, t)
      home_label = t.("home")
      lang_prefix = content.meta["lang_prefix"] || ""
      home_url = if lang_prefix == "", do: "/", else: "/#{lang_prefix}/"

      render_html(crumbs, t) <>
        render_json_ld(crumbs, base_url, home_label, home_url)
    else
      ""
    end
  end

  defp build_crumbs(content, t) do
    url_prefix = content.meta["url_prefix"] || ""
    lang_prefix = content.meta["lang_prefix"] || ""
    title = content.title || ""

    case url_prefix do
      "" ->
        [{title, nil}]

      prefix ->
        section_name = t.("#{prefix}_title")

        section_url =
          case lang_prefix do
            "" -> "/#{prefix}/"
            lp -> "/#{lp}/#{prefix}/"
          end

        [{section_name, section_url}, {title, nil}]
    end
  end

  defp render_html(crumbs, t) do
    case crumbs do
      [{_title, nil} | _] ->
        ""

      [{section_name, section_url} | _] ->
        escaped = Sayfa.Block.escape_html(section_name)
        label = t.("back_to_all") |> String.replace("%{section}", escaped)

        icon =
          ~s(<svg class="back-link-icon" width="14" height="14" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24" aria-hidden="true"><path d="M15 18l-6-6 6-6"/></svg>)

        ~s(<a href="#{section_url}" class="back-link">#{icon}#{label}</a>)
    end
  end

  defp render_json_ld(crumbs, base_url, home_label, home_url) do
    all_crumbs = [{home_label, home_url} | crumbs]

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
