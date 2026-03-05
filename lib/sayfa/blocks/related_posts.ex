defmodule Sayfa.Blocks.RelatedPosts do
  @moduledoc """
  Related posts block.

  Finds posts sharing the most tags/categories with the current post and
  renders up to 3 related posts with title, date, and first category.

  ## Assigns

  - `:content` — current `Sayfa.Content` struct
  - `:contents` — list of all site contents (injected by block helper)
  - `:limit` — number of related posts to show (default: 3)

  ## Examples

      <%= @block.(:related_posts) %>
      <%= @block.(:related_posts, limit: 5) %>

  """

  @behaviour Sayfa.Behaviours.Block

  alias Sayfa.Block
  alias Sayfa.Content

  @impl true
  def name, do: :related_posts

  @impl true
  def render(assigns) do
    content = Map.get(assigns, :content)
    contents = Map.get(assigns, :contents, [])
    limit = Map.get(assigns, :limit, 3)
    t = Map.get(assigns, :t, Sayfa.I18n.default_translate_function())
    lang = Map.get(assigns, :lang)
    site = Map.get(assigns, :site, %{})

    if content do
      related = find_related(content, contents, lang, limit)

      if related == [] do
        ""
      else
        heading = Block.escape_html(t.("related_posts"))
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

  defp find_related(content, contents, lang, limit) do
    current_tags = MapSet.new(content.tags || [])
    current_cats = MapSet.new(content.categories || [])
    current_slug = content.slug

    contents
    |> Content.all_of_type("posts")
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

  defp render_item(post, lang, site) do
    url = Content.url(post)
    title = Block.escape_html(post.title)
    first_cat = List.first(post.categories || [])

    date_html =
      if post.date do
        "<time class=\"content-card-date\">#{Sayfa.DateFormat.format(post.date, lang || :en, site)}</time>"
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
