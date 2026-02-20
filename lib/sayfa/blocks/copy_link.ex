defmodule Sayfa.Blocks.CopyLink do
  @moduledoc """
  Copy link button block.

  Renders a "Copy link" button that copies the current page URL to clipboard,
  with inline JavaScript for the copy functionality.

  ## Assigns

  No required assigns. This block is self-contained.

  ## Examples

      <%= @block.(:copy_link, []) %>

  """

  @behaviour Sayfa.Behaviours.Block

  @impl true
  def name, do: :copy_link

  @impl true
  def render(assigns) do
    t = Map.get(assigns, :t, Sayfa.I18n.default_translate_function())
    copy_link_text = t.("copy_link")
    copied_text = t.("copied")

    """
    <div class="mt-10 pt-6 border-t border-slate-200 dark:border-slate-700/50 flex items-center gap-3">\
      <button onclick="(function(btn){navigator.clipboard.writeText(window.location.href).then(function(){btn.querySelector('span').textContent='#{copied_text}';setTimeout(function(){btn.querySelector('span').textContent='#{copy_link_text}'},2000)})})(this)" class="inline-flex items-center gap-2 px-3 py-2 rounded-lg border border-slate-200 dark:border-slate-700 text-sm text-slate-500 dark:text-slate-400 hover:text-primary hover:border-primary/30 dark:hover:text-primary-400 dark:hover:border-primary-700/40">\
        <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24"><path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"/><path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"/></svg>\
        <span>#{copy_link_text}</span>\
      </button>\
    </div>\
    """
  end
end
