defmodule Sayfa.Blocks.TagCloud do
  @moduledoc """
  Tag cloud block.

  Renders a section with links to tag archive pages, sized by frequency.

  ## Assigns

  - `:contents` — list of all site contents (injected by block helper)

  ## Examples

      <%= @block.(:tag_cloud) %>

  """

  @behaviour Sayfa.Behaviours.Block

  alias Sayfa.Block
  alias Sayfa.Content

  @impl true
  def name, do: :tag_cloud

  @impl true
  def render(assigns) do
    contents = Map.get(assigns, :contents, [])
    tag_groups = Content.group_by_tag(contents)

    if tag_groups == %{} do
      ""
    else
      max_count = tag_groups |> Map.values() |> Enum.map(&length/1) |> Enum.max(fn -> 1 end)

      items =
        tag_groups
        |> Enum.sort_by(fn {tag, _} -> tag end)
        |> Enum.map_join("\n  ", fn {tag, items} ->
          count = length(items)
          size = size_class(count, max_count)
          slug = Slug.slugify(tag)
          "<a href=\"/tags/#{Block.escape_html(slug)}/\" class=\"tag-#{size}\" title=\"#{count} posts\">#{Block.escape_html(tag)}</a>"
        end)

      "<section class=\"tag-cloud\">\n  #{items}\n</section>"
    end
  end

  defp size_class(count, max_count) when max_count > 0 do
    ratio = count / max_count

    cond do
      ratio > 0.8 -> "xl"
      ratio > 0.6 -> "lg"
      ratio > 0.4 -> "md"
      ratio > 0.2 -> "sm"
      true -> "xs"
    end
  end

  defp size_class(_, _), do: "xs"
end
