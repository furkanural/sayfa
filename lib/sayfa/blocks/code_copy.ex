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
    t = Map.get(assigns, :t, Sayfa.I18n.default_translate_function())
    copy_text = t.("copy")
    copied_text = t.("code_copied")

    ~s(<div id="sayfa-code-copy" hidden data-selector="#{selector}" data-copy-text="#{copy_text}" data-copied-text="#{copied_text}"></div>)
  end
end
