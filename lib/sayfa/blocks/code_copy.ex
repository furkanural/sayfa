defmodule Sayfa.Blocks.CodeCopy do
  @moduledoc """
  Code copy button block.

  Renders a `<script>` tag that wraps code blocks with a header bar
  containing a language label and copy button with icon toggle.

  ## Assigns

  - `:selector` — CSS selector for code blocks (default: `"pre code"`)

  ## Examples

      <%= @block.(:code_copy) %>
      <%= @block.(:code_copy, selector: ".highlight code") %>

  """

  @behaviour Sayfa.Behaviours.Block

  alias Sayfa.Block

  @impl true
  def name, do: :code_copy

  @impl true
  def render(assigns) do
    selector = Block.escape_html(Map.get(assigns, :selector, "pre code"))

    """
    <script>
    (function() {
      document.querySelectorAll('#{selector}').forEach(function(block) {
        var pre = block.parentNode;
        if (pre.parentNode.classList.contains('not-prose')) return;
        var lang = block.className.replace(/^language-/, '') || '';
        var wrapper = document.createElement('div');
        wrapper.className = 'not-prose my-6 rounded-lg overflow-hidden border border-slate-200 dark:border-slate-700';
        var header = document.createElement('div');
        header.className = 'flex items-center justify-between px-4 py-2 bg-slate-800 text-slate-400';
        header.innerHTML = '<span class="text-xs font-mono">' + lang + '</span>' +
          '<button class="copy-btn inline-flex items-center gap-1.5 text-xs text-slate-400 hover:text-slate-200" onclick="(function(btn){var code=btn.closest(\\'.not-prose\\').querySelector(\\'code\\').textContent;navigator.clipboard.writeText(code).then(function(){btn.classList.add(\\'copied\\');btn.querySelector(\\'.copy-label\\').textContent=\\'Copied\\';setTimeout(function(){btn.classList.remove(\\'copied\\');btn.querySelector(\\'.copy-label\\').textContent=\\'Copy\\'},2000)})})(this)">' +
          '<svg class="w-3.5 h-3.5 icon-copy" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><rect width="14" height="14" x="8" y="8" rx="2" ry="2"/><path d="M4 16c-1.1 0-2-.9-2-2V4c0-1.1.9-2 2-2h10c1.1 0 2 .9 2 2"/></svg>' +
          '<svg class="w-3.5 h-3.5 icon-check text-green-400" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M20 6 9 17l-5-5"/></svg>' +
          '<span class="copy-label">Copy</span></button>';
        pre.style.margin = '0';
        pre.className = 'p-4 bg-slate-900 text-slate-100 overflow-x-auto m-0';
        var parent = pre.parentNode;
        parent.insertBefore(wrapper, pre);
        wrapper.appendChild(header);
        wrapper.appendChild(pre);
      });
    })();
    </script>\
    """
  end
end
