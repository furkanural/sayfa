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
      "#{featured_html}<div class=\"max-w-2xl mx-auto px-5 sm:px-6 pb-16\">\n  <div class=\"space-y-12\">\n#{Enum.join(sections, "\n")}\n  </div>\n</div>"
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
        ~s(<span class="inline-flex items-center gap-1"><svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24"><rect width="18" height="18" x="3" y="4" rx="2"/><path d="M16 2v4M8 2v4m-5 4h18"/></svg> #{Sayfa.DateFormat.format(content.date, lang || :en, site)}</span>)
      else
        ""
      end

    reading_time_html =
      if reading_time do
        ~s(<span class="inline-flex items-center gap-1"><svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24"><circle cx="12" cy="12" r="10"/><path d="M12 6v6l4 2"/></svg> #{reading_time}</span>)
      else
        ""
      end

    tag_html =
      if first_tag do
        ~s(<span class="inline-flex items-center gap-0.5 h-5 px-1.5 rounded text-xs font-medium bg-primary-50 text-primary dark:bg-primary-900/30 dark:text-primary-400"><svg class="w-2.5 h-2.5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><line x1="4" x2="20" y1="9" y2="9"/><line x1="4" x2="20" y1="15" y2="15"/><line x1="10" x2="8" y1="3" y2="21"/><line x1="16" x2="14" y1="3" y2="21"/></svg>#{Block.escape_html(first_tag)}</span>)
      else
        ""
      end

    description_html =
      if description != "" do
        ~s(<p class="mt-2 text-slate-500 dark:text-slate-400 leading-relaxed line-clamp-2">#{description}</p>)
      else
        ""
      end

    """
    <section class="max-w-2xl mx-auto px-5 sm:px-6 pb-14">
      <a href="#{url}" class="featured-accent group block pl-5 py-4">
        <span class="inline-flex items-center gap-1.5 text-xs font-medium text-primary dark:text-primary-400 uppercase tracking-wide mb-2">
          <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M13 2 3 14h9l-1 8 10-12h-9l1-8z"/></svg> #{Block.escape_html(t.("featured"))}
        </span>
        <h2 class="text-xl sm:text-2xl font-bold text-slate-900 dark:text-slate-50 group-hover:text-primary dark:group-hover:text-primary-400">#{title}</h2>
        #{description_html}
        <div class="mt-3 flex flex-wrap items-center gap-3 text-sm text-slate-400 dark:text-slate-500">
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
        "notes" -> "grid grid-cols-1 sm:grid-cols-2 gap-3"
        "projects" -> "space-y-3"
        _ -> "space-y-0 divide-y divide-slate-200/70 dark:divide-slate-800"
      end

    """
        <div>
          <div class="flex items-center justify-between mb-6">
            <h2 class="text-lg sm:text-xl font-semibold text-slate-900 dark:text-slate-50">#{heading}</h2>
            <a href="#{lang_prefix}/#{type}/" class="inline-flex items-center gap-1 text-sm text-primary dark:text-primary-400 hover:text-primary-dark dark:hover:text-primary-300">#{view_all_text} <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="m9 18 6-6-6-6"/></svg></a>
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
        ~s(<time datetime="#{content.date}" class="text-xs text-slate-400 dark:text-slate-500">#{Sayfa.DateFormat.format(content.date, lang || :en, site)}</time>)
      else
        ""
      end

    """
            <a href="#{url}" class="group block rounded-lg border border-slate-200/70 dark:border-slate-800 bg-slate-50 dark:bg-slate-800/50 p-4 hover:border-primary/30 dark:hover:border-primary/30 transition-colors">
              <h3 class="text-sm font-medium text-slate-800 dark:text-slate-200 group-hover:text-primary dark:group-hover:text-primary-400">#{title}</h3>
              <div class="mt-2">#{date_html}</div>
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
        ~s(<p class="mt-1.5 text-sm text-slate-500 dark:text-slate-400 leading-relaxed line-clamp-2">#{Block.escape_html(description)}</p>)
      else
        ""
      end

    status_html =
      if status do
        ~s(<span class="inline-flex items-center h-5 px-1.5 rounded text-xs font-medium bg-emerald-50 text-emerald-600 dark:bg-emerald-900/30 dark:text-emerald-400">#{Block.escape_html(status)}</span>)
      else
        ""
      end

    tag_html =
      if first_tag do
        ~s(<span class="inline-flex items-center gap-0.5 h-5 px-1.5 rounded text-xs font-medium bg-slate-100 text-slate-500 dark:bg-slate-800 dark:text-slate-400"><svg class="w-2.5 h-2.5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><line x1="4" x2="20" y1="9" y2="9"/><line x1="4" x2="20" y1="15" y2="15"/><line x1="10" x2="8" y1="3" y2="21"/><line x1="16" x2="14" y1="3" y2="21"/></svg>#{Block.escape_html(first_tag)}</span>)
      else
        ""
      end

    """
            <a href="#{url}" class="group block rounded-lg border border-slate-200/70 dark:border-slate-800 bg-slate-50 dark:bg-slate-800/50 p-4 hover:border-primary/30 dark:hover:border-primary/30 transition-colors">
              <div class="flex items-center gap-2">
                <h3 class="text-sm font-medium text-slate-800 dark:text-slate-200 group-hover:text-primary dark:group-hover:text-primary-400">#{title}</h3>
                #{status_html}
              </div>
              #{description_html}
              <div class="mt-2.5 flex flex-wrap items-center gap-2">#{tag_html}</div>
            </a>\
    """
  end

  defp render_item(_type, content, lang, site) do
    url = Content.url(content)
    title = Block.escape_html(content.title)

    date_html =
      if content.date do
        ~s(<span class="text-sm text-slate-400 dark:text-slate-500 tabular-nums">#{Sayfa.DateFormat.format(content.date, lang || :en, site)}</span>)
      else
        ""
      end

    """
            <a href="#{url}" class="group flex items-baseline gap-4 py-2.5 hover:text-primary dark:hover:text-primary-400">
              #{date_html}
              <span class="text-sm font-medium text-slate-800 dark:text-slate-200 group-hover:text-primary dark:group-hover:text-primary-400">#{title}</span>
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
