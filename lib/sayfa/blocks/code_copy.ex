defmodule Sayfa.Blocks.CodeCopy do
  @moduledoc """
  Code copy button block.

  Renders a `<script>` tag that adds clipboard copy buttons to code blocks.

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
        var btn = document.createElement('button');
        btn.className = 'code-copy-btn';
        btn.textContent = 'Copy';
        btn.addEventListener('click', function() {
          navigator.clipboard.writeText(block.textContent).then(function() {
            btn.textContent = 'Copied!';
            setTimeout(function() { btn.textContent = 'Copy'; }, 2000);
          });
        });
        block.parentNode.style.position = 'relative';
        block.parentNode.insertBefore(btn, block);
      });
    })();
    </script>\
    """
  end
end
