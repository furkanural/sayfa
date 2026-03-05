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
    t = Map.get(assigns, :t, Sayfa.I18n.default_translate_function())
    toc = get_toc(content)

    if toc == [] do
      ""
    else
      case variant do
        :mobile -> render_mobile(toc, t)
        _ -> render_sidebar(toc, t)
      end
    end
  end

  defp render_sidebar(toc, t) do
    items = Enum.map_join(toc, "\n", &render_sidebar_entry/1)
    heading = Block.escape_html(t.("on_this_page"))

    """
    <nav class="toc-nav">\
      <h2 class="toc-heading">#{heading}</h2>\
      <ul class="toc-list">\
    #{items}\
      </ul>\
    </nav>\
    """
  end

  defp render_mobile(toc, t) do
    items = Enum.map_join(toc, "\n", &render_mobile_entry/1)
    heading = Block.escape_html(t.("on_this_page"))

    """
    <details class="toc-mobile-box">\
      <summary class="toc-mobile-summary">\
        <svg class="toc-summary-icon" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24" aria-hidden="true"><line x1="4" x2="20" y1="6" y2="6"/><line x1="4" x2="20" y1="12" y2="12"/><line x1="10" x2="20" y1="18" y2="18"/></svg>\
        #{heading}\
      </summary>\
      <ul class="toc-mobile-list">\
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
      "    <li><a href=\"##{escaped_id}\" class=\"toc-link-l3\">#{escaped_text}</a></li>"
    else
      "    <li><a href=\"##{escaped_id}\" class=\"toc-link-l2\">#{escaped_text}</a></li>"
    end
  end

  defp render_mobile_entry(entry) do
    {id, text, level} = normalize_entry(entry)
    escaped_id = Block.escape_html(id)
    escaped_text = Block.escape_html(text)

    if level > 2 do
      "    <li class=\"toc-mobile-item-l3\"><a href=\"##{escaped_id}\" class=\"toc-mobile-link-l3\">#{escaped_text}</a></li>"
    else
      "    <li><a href=\"##{escaped_id}\" class=\"toc-mobile-link-l2\">#{escaped_text}</a></li>"
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
