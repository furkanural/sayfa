defmodule Sayfa.Blocks.TOC do
  @moduledoc """
  Table of contents block.

  Renders a navigation list of anchor links from the content's extracted TOC.
  Reads `content.meta["toc"]` which is populated by the builder's enrichment stage.

  ## Assigns

  - `:content` — current `Sayfa.Content` struct with `meta["toc"]`

  ## Examples

      <%= @block.(:toc) %>

  """

  @behaviour Sayfa.Behaviours.Block

  alias Sayfa.Block

  @impl true
  def name, do: :toc

  @impl true
  def render(assigns) do
    content = Map.get(assigns, :content)
    toc = get_toc(content)

    if toc == [] do
      ""
    else
      items =
        Enum.map_join(toc, "\n  ", fn entry ->
          {id, text, level} = normalize_entry(entry)
          indent = String.duplicate("  ", max(level - 2, 0))
          "#{indent}<li><a href=\"##{Block.escape_html(id)}\">#{Block.escape_html(text)}</a></li>"
        end)

      "<nav class=\"toc\">\n  <ul>\n  #{items}\n  </ul>\n</nav>"
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
