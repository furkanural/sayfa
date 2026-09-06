defmodule Sayfa.Blocks.MarkdownLink do
  @moduledoc """
  Markdown mirror link block.

  Renders a "View Markdown" link and a "Copy Markdown" button pointing to the
  current page's Markdown mirror (see `Sayfa.MarkdownMirror`), making the
  LLM-friendly version discoverable to human readers — the pattern popularized
  by docs platforms such as Mintlify.

  Renders nothing when the page has no mirror (e.g. list pages, the `"index"`
  slug) or when mirrors are disabled via `markdown_mirrors: false`.

  The copy button fetches the mirror and writes it to the clipboard; the
  JavaScript is handled via event delegation in enhancements.js.

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
      view_text = t.("view_markdown")
      copy_text = t.("copy_markdown")
      copied_text = t.("copied")

      """
      <a href="#{url}" class="copy-link markdown-link">\
        <svg class="icon-4" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24" aria-hidden="true"><path d="M19.5 14.25v-2.625a3.375 3.375 0 0 0-3.375-3.375h-1.5A1.125 1.125 0 0 1 13.5 7.125v-1.5a3.375 3.375 0 0 0-3.375-3.375H8.25m2.25 0H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 0 0-9-9Z"/></svg>\
        <span>#{view_text}</span>\
      </a>\
      <button data-action="copy-markdown" data-url="#{url}" data-copy-text="#{copy_text}" data-copied-text="#{copied_text}" class="copy-link">\
        <svg class="icon-4" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24" aria-hidden="true"><path d="M16.5 8.25V6a2.25 2.25 0 0 0-2.25-2.25H6A2.25 2.25 0 0 0 3.75 6v8.25A2.25 2.25 0 0 0 6 16.5h2.25m8.25-8.25H18a2.25 2.25 0 0 1 2.25 2.25V18A2.25 2.25 0 0 1 18 20.25h-7.5A2.25 2.25 0 0 1 8.25 18v-7.5a2.25 2.25 0 0 1 2.25-2.25h6Z"/></svg>\
        <span aria-live="polite">#{copy_text}</span>\
      </button>\
      """
    else
      _ -> ""
    end
  end
end
