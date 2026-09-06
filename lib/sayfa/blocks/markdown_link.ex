defmodule Sayfa.Blocks.MarkdownLink do
  @moduledoc """
  Markdown mirror copy block.

  Renders a "Copy as Markdown" button that fetches the current page's Markdown
  mirror (see `Sayfa.MarkdownMirror`) and writes it to the clipboard, so
  readers can paste the page straight into ChatGPT, Claude, etc. — the pattern
  popularized by docs platforms such as Mintlify.

  Renders nothing when the page has no mirror (e.g. list pages, the `"index"`
  slug) or when mirrors are disabled via `markdown_mirrors: false`.

  The JavaScript is handled via event delegation in enhancements.js. On small
  screens the theme collapses the button to its icon only; the `aria-label`
  keeps it accessible.

  ## Assigns

  - `:content` — the current `Sayfa.Content` (from template context)
  - `:site` — the site configuration map (from template context)

  ## Examples

      <%= @block.(:markdown_link, []) %>

  """

  @behaviour Sayfa.Behaviours.Block

  alias Sayfa.MarkdownMirror

  @impl true
  def name, do: :markdown_link

  @impl true
  def render(assigns) do
    content = Map.get(assigns, :content)
    site = Map.get(assigns, :site, %{})
    t = Map.get(assigns, :t, Sayfa.I18n.default_translate_function())

    with %Sayfa.Content{} <- content,
         true <- MarkdownMirror.enabled?(site),
         url when is_binary(url) <- MarkdownMirror.url(content) do
      copy_text = t.("copy_as_markdown")
      copied_text = t.("copied")

      """
      <button data-action="copy-markdown" data-url="#{url}" data-copy-text="#{copy_text}" data-copied-text="#{copied_text}" class="copy-link" aria-label="#{copy_text}">\
        <svg class="icon-4" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24" aria-hidden="true"><path d="M16.5 8.25V6a2.25 2.25 0 0 0-2.25-2.25H6A2.25 2.25 0 0 0 3.75 6v8.25A2.25 2.25 0 0 0 6 16.5h2.25m8.25-8.25H18a2.25 2.25 0 0 1 2.25 2.25V18A2.25 2.25 0 0 1 18 20.25h-7.5A2.25 2.25 0 0 1 8.25 18v-7.5a2.25 2.25 0 0 1 2.25-2.25h6Z"/></svg>\
        <span aria-live="polite">#{copy_text}</span>\
      </button>\
      """
    else
      _ -> ""
    end
  end
end
