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
    <button onclick="(function(btn){navigator.clipboard.writeText(window.location.href).then(function(){btn.querySelector('span').textContent='#{copied_text}';setTimeout(function(){btn.querySelector('span').textContent='#{copy_link_text}'},2000)})})(this)" class="inline-flex items-center gap-1.5 text-slate-400 dark:text-slate-500 hover:text-primary dark:hover:text-primary-400 cursor-pointer">\
      <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24"><path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"/><path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"/></svg>\
      <span>#{copy_link_text}</span>\
    </button>\
    """
  end
end
