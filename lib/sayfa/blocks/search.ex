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
    <div id="search-modal" class="fixed inset-0 z-[100] hidden" role="dialog" aria-modal="true" aria-label="#{search_label}" aria-hidden="true">\
      <div id="search-backdrop" class="absolute inset-0 bg-black/50 backdrop-blur-md"></div>\
      <div class="relative flex items-start justify-center pt-[15vh] px-4">\
        <div id="search-container" class="search-modal-container w-full max-w-xl bg-white dark:bg-slate-800 rounded-xl shadow-2xl ring-1 ring-slate-200 dark:ring-slate-700 flex flex-col max-h-[70vh]">\
          <div class="flex items-center justify-between px-4 pt-3 pb-1 flex-shrink-0">\
            <div class="flex items-center gap-2">\
              <span class="text-sm font-medium text-slate-500 dark:text-slate-400">#{search_label}</span>\
              <kbd class="hidden md:inline-flex items-center gap-0.5 text-[10px] font-medium font-mono text-slate-400 dark:text-slate-500 border border-slate-200 dark:border-slate-700 rounded px-1.5 py-0.5">Esc</kbd>\
            </div>\
            <button id="search-close" class="p-1.5 text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 hover:bg-slate-100 dark:hover:bg-slate-700 rounded-lg" aria-label="Close">\
              <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24"><path d="M6 18 18 6M6 6l12 12"/></svg>\
            </button>\
          </div>\
          <div id="search" class="px-4 pb-4 overflow-y-auto flex-1 min-h-0"></div>\
        </div>\
      </div>\
    </div>\
    <script>\
    (function(){var modal=document.getElementById('search-modal'),loaded=false;function open(){if(!loaded){loaded=true;var l=document.createElement('link');l.rel='stylesheet';l.href='/pagefind/pagefind-ui.css';document.head.appendChild(l);var s=document.createElement('script');s.src='/pagefind/pagefind-ui.js';s.onload=function(){try{new PagefindUI({element:'#search',showSubResults:#{show_sub_results},showImages:#{show_images},translations:{placeholder:'#{search_placeholder}',zero_results:'#{search_no_results}'}})}catch(e){document.getElementById('search').innerHTML='<p class=\"p-4 text-sm text-slate-500\">Search is not available.</p>'}var inp=document.querySelector('#search .pagefind-ui__search-input');if(inp){inp.id='search-input';inp.name='search'}setTimeout(function(){var i=modal.querySelector('.pagefind-ui__search-input');if(i)i.focus()},100)};s.onerror=function(){document.getElementById('search').innerHTML='<p class=\"p-4 text-sm text-slate-500\">Search is not available.</p>'};document.head.appendChild(s)}else{setTimeout(function(){var i=modal.querySelector('.pagefind-ui__search-input');if(i){i.focus();i.select()}},50)}modal.classList.remove('hidden');modal.setAttribute('aria-hidden','false');document.body.style.overflow='hidden'}function close(){modal.classList.add('hidden');modal.setAttribute('aria-hidden','true');document.body.style.overflow='';var t=document.getElementById('search-trigger');if(t)t.focus()}document.addEventListener('click',function(e){if(e.target&&e.target.id==='search-trigger'||e.target.closest&&e.target.closest('#search-trigger'))open();if(e.target&&e.target.id==='search-backdrop')close();if(e.target&&(e.target.id==='search-close'||e.target.closest&&e.target.closest('#search-close')))close()});document.addEventListener('keydown',function(e){if((e.metaKey||e.ctrlKey)&&e.key==='k'){e.preventDefault();if(modal.classList.contains('hidden'))open();else close()}if(e.key==='Escape'&&!modal.classList.contains('hidden')){e.stopPropagation();close()}})})()\
    </script>\
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
