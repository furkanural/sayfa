defmodule Sayfa.Blocks.RecentArticles do
  @moduledoc """
  Recent articles block.

  Renders a chronological list of the most recent articles with date and title.

  ## Assigns

  - `:contents` — list of all site contents (injected by block helper)
  - `:limit` — number of articles to show (default: 5)
  - `:show_view_all` — whether to show "View all" link (default: false)

  ## Examples

      <%= @block.(:recent_articles, limit: 3) %>
      <%= @block.(:recent_articles, limit: 5, show_view_all: true) %>

  """

  @behaviour Sayfa.Behaviours.Block

  alias Sayfa.Block
  alias Sayfa.Content
  alias Sayfa.I18n

  @impl true
  def name, do: :recent_articles

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

    articles =
      contents
      |> Content.all_of_type("articles")
      |> Content.recent(limit)

    if articles == [] do
      ""
    else
      items = Enum.map_join(articles, "\n", &render_article_item(&1, lang, site))

      view_all_html =
        if show_view_all do
          "<a href=\"#{lang_prefix}/articles/\" class=\"section-link\">#{Block.escape_html(t.("view_all"))} <svg class=\"icon-3_5\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" viewBox=\"0 0 24 24\" aria-hidden=\"true\"><path d=\"m9 18 6-6-6-6\"/></svg></a>"
        else
          ""
        end

      """
      <section class="container-content section-spacing">\
        <div class="recent-section-header">\
          <h2 class="section-title">#{Block.escape_html(t.("recent_articles"))}</h2>\
          #{view_all_html}\
        </div>\
        <div class="recent-article-list">\
      #{items}\
        </div>\
      </section>\
      """
    end
  end

  defp render_article_item(article, lang, site) do
    url = Content.url(article)
    title = Block.escape_html(article.title)

    date_html =
      if article.date do
        "<time class=\"recent-article-date\">#{Sayfa.DateFormat.format(article.date, lang || :en, site)}</time>"
      else
        ""
      end

    """
        <a href="#{url}" class="recent-article-link">\
          #{date_html}\
          <span class="recent-article-title">#{title}</span>\
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
