defmodule Sayfa.Blocks.RecentContent do
  @moduledoc """
  Dynamic recent content block.

  Groups all content by `content_type`, excludes "pages", and renders a section
  for each type that has content (posts, notes, projects, talks, etc.).

  ## Assigns

  - `:contents` — list of all site contents (injected by block helper)
  - `:limit` — number of items per type to show (default: 5)

  ## Examples

      <%= @block.(:recent_content, limit: 3) %>

  """

  @behaviour Sayfa.Behaviours.Block

  alias Sayfa.Block
  alias Sayfa.Content

  @impl true
  def name, do: :recent_content

  @impl true
  def render(assigns) do
    contents = Map.get(assigns, :contents, [])
    limit = Map.get(assigns, :limit, 5)

    sections =
      contents
      |> Enum.group_by(fn c -> c.meta["content_type"] end)
      |> Enum.reject(fn {type, _} -> type == "pages" or is_nil(type) end)
      |> Enum.sort_by(fn {type, _} -> type end)
      |> Enum.map(fn {type, items} ->
        recent_items = Content.recent(items, limit)
        render_section(type, recent_items)
      end)

    if sections == [] do
      ""
    else
      "<section class=\"recent-content\">\n#{Enum.join(sections, "\n")}\n</section>"
    end
  end

  defp render_section(type, items) do
    heading = type |> String.capitalize()
    items_html = Enum.map_join(items, "\n  ", &render_item(&1))

    "  <section class=\"recent-#{type}\">\n    <h2>#{heading}</h2>\n    <ul>\n  #{items_html}\n    </ul>\n  </section>"
  end

  defp render_item(content) do
    url = Content.url(content)
    title = Block.escape_html(content.title)

    date_html =
      if content.date, do: " <time datetime=\"#{content.date}\">#{content.date}</time>", else: ""

    "  <li><a href=\"#{url}\">#{title}</a>#{date_html}</li>"
  end
end
