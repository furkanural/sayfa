defmodule Sayfa.Blocks.Search do
  @moduledoc """
  Pagefind search modal block.

  Renders a full-screen modal overlay with Pagefind search UI, plus a trigger
  button for the header. Pagefind CSS/JS are lazy-loaded on first open for
  performance.

  ## Assigns

  - `:show_sub_results` — show sub-results in search (default: `true`)
  - `:show_images` — show images in results (default: `true`)
  - `:t` — translation function (optional)

  ## Examples

      <%= @block.(:search) %>

  """

  @behaviour Sayfa.Behaviours.Block

  alias Sayfa.Block

  @impl true
  def name, do: :search

  @impl true
  def render(assigns) do
    show_sub_results = Map.get(assigns, :show_sub_results, true)
    show_images = Map.get(assigns, :show_images, true)
    t = Map.get(assigns, :t, &default_t/1)
    search_label = Block.escape_html(t.("search"))
    search_placeholder = Block.escape_html(t.("search_placeholder"))
    search_no_results = Block.escape_html(t.("search_no_results"))

    """
    <div id="search-modal" class="fixed inset-0 z-100 hidden" role="dialog" aria-modal="true" aria-label="#{search_label}" aria-hidden="true" data-show-sub-results="#{show_sub_results}" data-show-images="#{show_images}" data-placeholder="#{search_placeholder}" data-no-results="#{search_no_results}">\
      <div id="search-backdrop" class="absolute inset-0 bg-black/50 backdrop-blur-sm"></div>\
      <div class="relative flex items-start justify-center pt-[12vh] px-4">\
        <div id="search-container" class="search-modal-container relative w-full max-w-lg bg-white dark:bg-slate-900 rounded-xl shadow-2xl ring-1 ring-slate-900/10 dark:ring-slate-100/10 flex flex-col max-h-[70vh]">\
          <div id="search" class="overflow-y-auto flex-1 min-h-0"></div>\
          <kbd id="search-esc" class="hidden md:inline-flex items-center absolute top-[1.1rem] right-4 z-10 search-kbd">Esc</kbd>\
          <div id="search-footer" class="flex items-center gap-3 border-t border-slate-200 dark:border-slate-800 px-4 py-2.5 text-xs text-slate-400 dark:text-slate-500 shrink-0">\
            <span class="flex items-center gap-1"><kbd class="search-kbd">↵</kbd> select</span>\
            <span class="flex items-center gap-1"><kbd class="search-kbd">↑↓</kbd> navigate</span>\
            <span class="flex items-center gap-1"><kbd class="search-kbd">esc</kbd> close</span>\
          </div>\
        </div>\
      </div>\
    </div>\
    """
  end

  @doc """
  Renders the search trigger button for use in the header.

  Returns a small magnifying glass icon button with a `Cmd+K` / `Ctrl+K`
  keyboard hint badge.

  ## Examples

      Sayfa.Blocks.Search.render_trigger(%{t: t_fn})

  """
  @spec render_trigger(map()) :: String.t()
  def render_trigger(assigns) do
    t = Map.get(assigns, :t, &default_t/1)
    search_label = Block.escape_html(t.("search"))

    """
    <button id="search-trigger" class="flex items-center gap-1.5 p-2 text-slate-500 dark:text-slate-400 hover:text-slate-900 dark:hover:text-slate-100" aria-label="#{search_label}">\
      <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24" aria-hidden="true"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/></svg>\
      <kbd class="hidden md:inline-flex items-center text-[10px] font-medium font-mono text-slate-400 dark:text-slate-500 border border-slate-200 dark:border-slate-700 rounded px-1 py-0.5">⌘K</kbd>\
    </button>\
    """
  end

  defp default_t("search"), do: "Search"
  defp default_t("search_placeholder"), do: "Search..."
  defp default_t("search_no_results"), do: "No results found"
  defp default_t(key), do: key
end
