defmodule Sayfa.Blocks.RelatedContent do
  @moduledoc """
  Related content block.

  Finds content items sharing the most tags/categories with the current item and
  renders up to 3 related items with title, date, and first category.

  Unlike `RelatedArticles` which is hardcoded to articles, this block auto-detects the
  current content's type or accepts an explicit `type:` assign.

  ## Assigns

  - `:content` — current `Sayfa.Content` struct
  - `:contents` — list of all site contents (injected by block helper)
  - `:type` — content type to search (e.g. `"notes"`, `"articles"`); defaults to current content's type
  - `:limit` — number of related items to show (default: 3)

  ## Examples

      <%= @block.(:related_content) %>
      <%= @block.(:related_content, type: "notes", limit: 5) %>

  """

  @behaviour Sayfa.Behaviours.Block

  alias Sayfa.Block
  alias Sayfa.Content

  @impl true
  def name, do: :related_content

  @impl true
  def render(assigns) do
    content = Map.get(assigns, :content)
    contents = Map.get(assigns, :contents, [])
    limit = Map.get(assigns, :limit, 3)
    t = Map.get(assigns, :t, Sayfa.I18n.default_translate_function())
    lang = Map.get(assigns, :lang)
    site = Map.get(assigns, :site, %{})

    if content do
      type = Map.get(assigns, :type) || content_type(content)
      related = find_related(content, contents, type, lang, limit)

      if related == [] do
        ""
      else
        heading = Block.escape_html(t.("related_articles"))
        items = Enum.map_join(related, "\n", &render_item(&1, lang, site))

        """
        <section class="related-section">\
          <h2 class="related-title">#{heading}</h2>\
          <div class="related-grid">\
        #{items}\
          </div>\
        </section>\
        """
      end
    else
      ""
    end
  end

  defp content_type(content) do
    content.meta["url_prefix"] || "articles"
  end

  defp find_related(content, contents, type, lang, limit) do
    current_tags = MapSet.new(content.tags || [])
    current_cats = MapSet.new(content.categories || [])
    current_slug = content.slug

    contents
    |> Content.all_of_type(type)
    |> Enum.filter(fn c ->
      c.slug != current_slug and (is_nil(lang) or c.lang == lang)
    end)
    |> Enum.map(fn c ->
      tag_overlap = MapSet.intersection(current_tags, MapSet.new(c.tags || [])) |> MapSet.size()

      cat_overlap =
        MapSet.intersection(current_cats, MapSet.new(c.categories || [])) |> MapSet.size()

      {c, tag_overlap + cat_overlap}
    end)
    |> Enum.filter(fn {_, score} -> score > 0 end)
    |> Enum.sort_by(fn {_, score} -> score end, :desc)
    |> Enum.take(limit)
    |> Enum.map(fn {c, _} -> c end)
  end

  defp render_item(item, lang, site) do
    url = Content.url(item)
    title = Block.escape_html(item.title)
    first_cat = List.first(item.categories || [])

    date_html =
      if item.date do
        "<time class=\"content-card-date\">#{Sayfa.DateFormat.format(item.date, lang || :en, site)}</time>"
      else
        ""
      end

    cat_html =
      if first_cat do
        "<span class=\"chip-category\"><svg class=\"icon-2_5\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" viewBox=\"0 0 24 24\" aria-hidden=\"true\"><path d=\"M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z\"/></svg>#{Block.escape_html(first_cat)}</span>"
      else
        ""
      end

    """
        <a href="#{url}" class="content-card">\
          <h3 class="content-card-title-clamp">#{title}</h3>\
          <div class="content-card-meta">#{date_html} #{cat_html}</div>\
        </a>\
    """
  end
end
