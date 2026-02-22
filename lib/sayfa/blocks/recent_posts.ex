defmodule Sayfa.Blocks.RecentPosts do
  @moduledoc """
  Recent posts block.

  Renders a chronological list of the most recent posts with date and title.

  ## Assigns

  - `:contents` — list of all site contents (injected by block helper)
  - `:limit` — number of posts to show (default: 5)
  - `:show_view_all` — whether to show "View all" link (default: false)

  ## Examples

      <%= @block.(:recent_posts, limit: 3) %>
      <%= @block.(:recent_posts, limit: 5, show_view_all: true) %>

  """

  @behaviour Sayfa.Behaviours.Block

  alias Sayfa.Block
  alias Sayfa.Content
  alias Sayfa.I18n

  @impl true
  def name, do: :recent_posts

  @impl true
  def render(assigns) do
    contents = Map.get(assigns, :contents, [])
    limit = Map.get(assigns, :limit, 5)
    show_view_all = Map.get(assigns, :show_view_all, false)
    t = Map.get(assigns, :t, I18n.default_translate_function())
    lang = Map.get(assigns, :lang)
    site = Map.get(assigns, :site, %{})

    contents = filter_by_lang(contents, lang)
    lang_prefix = lang_prefix_path(lang, site)

    posts =
      contents
      |> Content.all_of_type("posts")
      |> Content.recent(limit)

    if posts == [] do
      ""
    else
      items = Enum.map_join(posts, "\n", &render_post_item(&1, lang, site))

      view_all_html =
        if show_view_all do
          "<a href=\"#{lang_prefix}/posts/\" class=\"inline-flex items-center gap-1 text-sm text-primary dark:text-primary-400 hover:text-primary-dark dark:hover:text-primary-300\">#{Block.escape_html(t.("view_all"))} <svg class=\"w-3.5 h-3.5\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" viewBox=\"0 0 24 24\" aria-hidden=\"true\"><path d=\"m9 18 6-6-6-6\"/></svg></a>"
        else
          ""
        end

      """
      <section class="container-content section-spacing">\
        <div class="flex items-center justify-between mb-6">\
          <h2 class="text-lg sm:text-xl font-semibold text-slate-900 dark:text-slate-50">#{Block.escape_html(t.("recent_posts"))}</h2>\
          #{view_all_html}\
        </div>\
        <div class="space-y-0 divide-y divide-slate-200/70 dark:divide-slate-800">\
      #{items}\
        </div>\
      </section>\
      """
    end
  end

  defp render_post_item(post, lang, site) do
    url = Content.url(post)
    title = Block.escape_html(post.title)

    date_html =
      if post.date do
        "<time class=\"shrink-0 text-sm tabular-nums text-slate-500 dark:text-slate-400 w-[5.5rem]\">#{Sayfa.DateFormat.format(post.date, lang || :en, site)}</time>"
      else
        ""
      end

    """
        <a href="#{url}" class="group flex items-baseline gap-4 py-4">\
          #{date_html}\
          <span class="text-slate-800 dark:text-slate-200 group-hover:text-primary dark:group-hover:text-primary-400">#{title}</span>\
        </a>\
    """
  end

  defp filter_by_lang(contents, nil), do: contents

  defp filter_by_lang(contents, lang) do
    Enum.filter(contents, &(&1.lang == lang))
  end

  defp lang_prefix_path(nil, _site), do: ""

  defp lang_prefix_path(lang, site) do
    case I18n.language_prefix(lang, site) do
      "" -> ""
      prefix -> "/#{prefix}"
    end
  end
end
