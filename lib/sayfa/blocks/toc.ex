defmodule Sayfa.Blocks.TOC do
  @moduledoc """
  Table of contents block.

  Renders a navigation list of headings for sidebar or mobile use.
  Supports two variants: `:sidebar` (default) for desktop border-l nav,
  and `:mobile` for a collapsible `<details>` element.

  ## Assigns

  - `:content` — current `Sayfa.Content` struct with `meta["toc"]`
  - `:variant` — `:sidebar` (default) or `:mobile`

  ## Examples

      <%= @block.(:toc) %>
      <%= @block.(:toc, variant: :mobile) %>

  """

  @behaviour Sayfa.Behaviours.Block

  alias Sayfa.Block

  @impl true
  def name, do: :toc

  @impl true
  def render(assigns) do
    content = Map.get(assigns, :content)
    variant = Map.get(assigns, :variant, :sidebar)
    toc = get_toc(content)

    if toc == [] do
      ""
    else
      case variant do
        :mobile -> render_mobile(toc)
        _ -> render_sidebar(toc)
      end
    end
  end

  defp render_sidebar(toc) do
    items = Enum.map_join(toc, "\n", &render_sidebar_entry/1)

    """
    <nav class="sticky top-20">\
      <h2 class="text-xs font-semibold text-slate-400 dark:text-slate-500 uppercase tracking-wider mb-4">On this page</h2>\
      <ul class="space-y-2.5 text-sm border-l border-slate-200 dark:border-slate-800">\
    #{items}\
      </ul>\
    </nav>\
    """
  end

  defp render_mobile(toc) do
    items = Enum.map_join(toc, "\n", &render_mobile_entry/1)

    """
    <details class="rounded-lg border border-slate-200/70 dark:border-slate-800 bg-slate-50 dark:bg-slate-800/50">\
      <summary class="flex items-center gap-2 cursor-pointer p-4 text-sm font-medium text-slate-700 dark:text-slate-300 select-none">\
        <svg class="w-4 h-4 text-slate-400" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24"><line x1="8" x2="21" y1="6" y2="6"/><line x1="8" x2="21" y1="12" y2="12"/><line x1="8" x2="21" y1="18" y2="18"/><line x1="3" x2="3.01" y1="6" y2="6"/><line x1="3" x2="3.01" y1="12" y2="12"/><line x1="3" x2="3.01" y1="18" y2="18"/></svg>\
        On this page\
      </summary>\
      <ul class="px-4 pb-4 space-y-2 text-sm">\
    #{items}\
      </ul>\
    </details>\
    """
  end

  defp render_sidebar_entry(entry) do
    {id, text, level} = normalize_entry(entry)
    escaped_id = Block.escape_html(id)
    escaped_text = Block.escape_html(text)

    if level > 2 do
      "    <li><a href=\"##{escaped_id}\" class=\"block pl-8 -ml-px border-l border-transparent hover:border-primary text-slate-400 dark:text-slate-500 hover:text-primary dark:hover:text-primary-400\">#{escaped_text}</a></li>"
    else
      "    <li><a href=\"##{escaped_id}\" class=\"block pl-4 -ml-px border-l border-transparent hover:border-primary text-slate-500 dark:text-slate-400 hover:text-primary dark:hover:text-primary-400\">#{escaped_text}</a></li>"
    end
  end

  defp render_mobile_entry(entry) do
    {id, text, level} = normalize_entry(entry)
    escaped_id = Block.escape_html(id)
    escaped_text = Block.escape_html(text)

    if level > 2 do
      "    <li class=\"ml-4\"><a href=\"##{escaped_id}\" class=\"text-slate-400 dark:text-slate-500 hover:text-primary dark:hover:text-primary-400\">#{escaped_text}</a></li>"
    else
      "    <li><a href=\"##{escaped_id}\" class=\"text-slate-500 dark:text-slate-400 hover:text-primary dark:hover:text-primary-400\">#{escaped_text}</a></li>"
    end
  end

  defp get_toc(nil), do: []
  defp get_toc(%{meta: %{"toc" => toc}}) when is_list(toc), do: toc
  defp get_toc(_), do: []

  defp normalize_entry(%{id: id, text: text, level: level}), do: {id, text, level}
  defp normalize_entry(%{"id" => id, "text" => text, "level" => level}), do: {id, text, level}
  defp normalize_entry({id, text, level}), do: {id, text, level}
  defp normalize_entry(_), do: {"", "", 2}
end
