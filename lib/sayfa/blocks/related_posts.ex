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
        <section class="mt-12 pt-8 border-t border-slate-200/70 dark:border-slate-800">\
          <h2 class="text-lg font-semibold text-slate-900 dark:text-slate-50 mb-6">#{heading}</h2>\
          <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">\
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
        "<time class=\"text-xs text-slate-400 dark:text-slate-500\">#{Sayfa.DateFormat.format(post.date, lang || :en, site)}</time>"
      else
        ""
      end

    cat_html =
      if first_cat do
        "<span class=\"inline-flex items-center gap-0.5 h-5 px-1.5 rounded text-xs font-medium bg-amber-50 text-amber-600 dark:bg-amber-900/20 dark:text-amber-400\"><svg class=\"w-2.5 h-2.5\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" viewBox=\"0 0 24 24\" aria-hidden=\"true\"><path d=\"M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z\"/></svg>#{Block.escape_html(first_cat)}</span>"
      else
        ""
      end

    """
        <a href="#{url}" class="group block rounded-lg border border-slate-200/70 dark:border-slate-800 bg-slate-50 dark:bg-slate-800/50 p-4 hover:border-primary/30 dark:hover:border-primary/30 transition-colors">\
          <h3 class="text-sm font-medium text-slate-800 dark:text-slate-200 group-hover:text-primary dark:group-hover:text-primary-400 line-clamp-2">#{title}</h3>\
          <div class="mt-2 flex items-center gap-2">#{date_html} #{cat_html}</div>\
        </a>\
    """
  end
end
