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

  @impl true
  def name, do: :recent_content

  @impl true
  def render(assigns) do
    contents = Map.get(assigns, :contents, [])
    limit = Map.get(assigns, :limit, 5)

    sections =
      contents
      |> Enum.group_by(fn c -> c.meta["content_type"] end)
      |> Enum.reject(fn {type, _} -> type == "pages" or is_nil(type) end)
      |> Enum.sort_by(fn {type, _} -> type end)
      |> Enum.map(fn {type, items} ->
        recent_items = Content.recent(items, limit)
        render_section(type, recent_items)
      end)

    if sections == [] do
      ""
    else
      "<div class=\"max-w-2xl mx-auto px-5 sm:px-6 pb-16\">\n  <div class=\"space-y-12\">\n#{Enum.join(sections, "\n")}\n  </div>\n</div>"
    end
  end

  defp render_section(type, items) do
    heading = type |> String.capitalize()
    items_html = Enum.map_join(items, "\n", &render_item(type, &1))

    """
        <div>
          <div class="flex items-center justify-between mb-6">
            <h2 class="text-lg sm:text-xl font-semibold text-slate-900 dark:text-slate-50">#{heading}</h2>
            <a href="/#{type}/" class="inline-flex items-center gap-1 text-sm text-primary dark:text-primary-400 hover:text-primary-dark dark:hover:text-primary-300">View all <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="m9 18 6-6-6-6"/></svg></a>
          </div>
          <div class="space-y-0 divide-y divide-slate-200/70 dark:divide-slate-800">
    #{items_html}
          </div>
        </div>\
    """
  end

  defp render_item("notes", content) do
    url = Content.url(content)
    title = Block.escape_html(content.title)

    date_html =
      if content.date do
        "<time class=\"mt-1.5 block text-xs text-slate-400 dark:text-slate-500\">#{format_date(content.date)}</time>"
      else
        ""
      end

    """
            <a href="#{url}" class="group block p-4 rounded-lg border border-slate-200/70 dark:border-slate-800 bg-slate-50 dark:bg-slate-800/50 hover:border-primary/30 dark:hover:border-primary-700/40">
              <h3 class="text-sm font-medium text-slate-800 dark:text-slate-200 group-hover:text-primary dark:group-hover:text-primary-400">#{title}</h3>
              #{date_html}
            </a>\
    """
  end

  defp render_item(_type, content) do
    url = Content.url(content)
    title = Block.escape_html(content.title)

    date_html =
      if content.date do
        "<time class=\"shrink-0 text-sm tabular-nums text-slate-400 dark:text-slate-500 w-[5.5rem]\">#{format_date(content.date)}</time>"
      else
        ""
      end

    """
            <a href="#{url}" class="group flex items-baseline gap-4 py-4">
              #{date_html}
              <span class="text-slate-800 dark:text-slate-200 group-hover:text-primary dark:group-hover:text-primary-400">#{title}</span>
            </a>\
    """
  end

  defp format_date(%Date{} = date) do
    Calendar.strftime(date, "%b %-d, %Y")
  end

  defp format_date(date), do: to_string(date)
end
