defmodule Sayfa.Blocks.RecentContent do
  @moduledoc """
  Dynamic recent content block.

  Groups all content by `content_type`, excludes "pages", and renders a section
  for each type that has content (posts, notes, projects, talks, etc.).

  ## Assigns

  - `:contents` — list of all site contents (injected by block helper)
  - `:limit` — number of items per type to show (default: 5)

  ## Examples

      <%= @block.(:recent_content, limit: 3) %>

  """

  @behaviour Sayfa.Behaviours.Block

  alias Sayfa.Block
  alias Sayfa.Content
  alias Sayfa.I18n

  @impl true
  def name, do: :recent_content

  @impl true
  def render(assigns) do
    contents = Map.get(assigns, :contents, [])
    limit = Map.get(assigns, :limit, 5)
    t = Map.get(assigns, :t, I18n.default_translate_function())
    lang = Map.get(assigns, :lang)
    site = Map.get(assigns, :site, %{})

    contents = filter_by_lang(contents, lang)

    lang_prefix = lang_prefix_path(lang, site)

    {featured, rest} = extract_featured(contents)
    featured_html = render_featured(featured, t, lang, site)

    sections =
      rest
      |> Enum.group_by(fn c -> c.meta["content_type"] end)
      |> Enum.reject(fn {type, _} -> type == "pages" or is_nil(type) end)
      |> Enum.sort_by(fn {type, _} -> type end)
      |> Enum.map(fn {type, items} ->
        recent_items = Content.recent(items, limit)
        render_section(type, recent_items, t, lang_prefix, lang, site)
      end)

    if sections == [] and featured_html == "" do
      ""
    else
      "#{featured_html}<div class=\"container-content section-spacing\">\n  <div class=\"space-y-12\">\n#{Enum.join(sections, "\n")}\n  </div>\n</div>"
    end
  end

  defp extract_featured(contents) do
    case Enum.find(contents, fn c -> c.meta["featured"] == true end) do
      nil -> {"", contents}
      featured -> {featured, List.delete(contents, featured)}
    end
  end

  defp render_featured("", _t, _lang, _site), do: ""

  defp render_featured(content, t, lang, site) do
    url = Content.url(content)
    title = Block.escape_html(content.title)
    description = Block.escape_html(content.meta["description"] || "")
    reading_time = content.meta["reading_time"]
    first_tag = List.first(content.tags || [])

    date_html =
      if content.date do
        ~s(<span class="featured-meta-item"><svg class="icon-3_5" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24" aria-hidden="true"><rect width="18" height="18" x="3" y="4" rx="2"/><path d="M16 2v4M8 2v4m-5 4h18"/></svg> #{Sayfa.DateFormat.format(content.date, lang || :en, site)}</span>)
      else
        ""
      end

    reading_time_label = I18n.t("min_read", lang || :en, site, count: reading_time)

    reading_time_html =
      if reading_time do
        ~s(<span class="featured-meta-item"><svg class="icon-3_5" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="10"/><path d="M12 6v6l4 2"/></svg> #{reading_time_label}</span>)
      else
        ""
      end

    tag_html =
      if first_tag do
        ~s(<span class="chip-tag"><svg class="icon-2_5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24" aria-hidden="true"><line x1="4" x2="20" y1="9" y2="9"/><line x1="4" x2="20" y1="15" y2="15"/><line x1="10" x2="8" y1="3" y2="21"/><line x1="16" x2="14" y1="3" y2="21"/></svg>#{Block.escape_html(first_tag)}</span>)
      else
        ""
      end

    description_html =
      if description != "" do
        ~s(<p class="featured-description">#{description}</p>)
      else
        ""
      end

    """
    <section class="container-content section-spacing">
      <a href="#{url}" class="featured-accent featured-link">
        <span class="featured-label">
          <svg class="icon-3_5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24" aria-hidden="true"><path d="M13 2 3 14h9l-1 8 10-12h-9l1-8z"/></svg> #{Block.escape_html(t.("featured"))}
        </span>
        <h2 class="featured-title">#{title}</h2>
        #{description_html}
        <div class="featured-meta">
          #{date_html}
          #{reading_time_html}
          #{tag_html}
        </div>
      </a>
    </section>
    """
  end

  defp render_section(type, items, t, lang_prefix, lang, site) do
    heading = t.("#{type}_title")
    items_html = Enum.map_join(items, "\n", &render_item(type, &1, lang, site))
    view_all_text = Block.escape_html(t.("view_all"))

    container_class =
      case type do
        "notes" -> "notes-grid"
        "projects" -> "cards-stack"
        _ -> "recent-post-list"
      end

    """
        <div>
          <div class="recent-section-header">
            <h2 class="section-title">#{heading}</h2>
            <a href="#{lang_prefix}/#{type}/" class="section-link">#{view_all_text} <svg class="icon-3_5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24" aria-hidden="true"><path d="m9 18 6-6-6-6"/></svg></a>
          </div>
          <div class="#{container_class}">
    #{items_html}
          </div>
        </div>\
    """
  end

  defp render_item("notes", content, lang, site) do
    url = Content.url(content)
    title = Block.escape_html(content.title)

    date_html =
      if content.date do
        ~s(<time datetime="#{content.date}" class="content-card-date">#{Sayfa.DateFormat.format(content.date, lang || :en, site)}</time>)
      else
        ""
      end

    """
            <a href="#{url}" class="content-card content-card-note">
              <h3 class="content-card-title">#{title}</h3>
              <div class="content-card-date-wrap">#{date_html}</div>
            </a>\
    """
  end

  defp render_item("projects", content, _lang, _site) do
    url = Content.url(content)
    title = Block.escape_html(content.title)
    description = content.meta["description"]
    status = content.meta["status"]
    first_tag = List.first(content.tags || [])

    description_html =
      if description do
        ~s(<p class="content-card-excerpt-clamp">#{Block.escape_html(description)}</p>)
      else
        ""
      end

    status_html =
      if status do
        ~s(<span class="chip-status">#{Block.escape_html(status)}</span>)
      else
        ""
      end

    tag_html =
      if first_tag do
        ~s(<span class="chip-tag"><svg class="icon-2_5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24" aria-hidden="true"><line x1="4" x2="20" y1="9" y2="9"/><line x1="4" x2="20" y1="15" y2="15"/><line x1="10" x2="8" y1="3" y2="21"/><line x1="16" x2="14" y1="3" y2="21"/></svg>#{Block.escape_html(first_tag)}</span>)
      else
        ""
      end

    """
            <a href="#{url}" class="content-card content-card-project">
              <div class="content-card-header">
                <h3 class="content-card-title">#{title}</h3>
                #{status_html}
              </div>
              #{description_html}
              <div class="content-card-meta">#{tag_html}</div>
            </a>\
    """
  end

  defp render_item(_type, content, lang, site) do
    url = Content.url(content)
    title = Block.escape_html(content.title)

    date_html =
      if content.date do
        ~s(<span class="entry-link-date">#{Sayfa.DateFormat.format(content.date, lang || :en, site)}</span>)
      else
        ""
      end

    """
            <a href="#{url}" class="entry-link-row">
              #{date_html}
              <span class="entry-link-title">#{title}</span>
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
