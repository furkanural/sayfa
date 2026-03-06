defmodule Sayfa.Blocks.TagCloud do
  @moduledoc """
  Tag cloud block.

  Renders a flex-wrap section with tag pills sized by frequency,
  each prefixed with a hash icon.

  ## Assigns

  - `:contents` — list of all site contents (injected by block helper)

  ## Examples

      <%= @block.(:tag_cloud) %>

  """

  @behaviour Sayfa.Behaviours.Block

  alias Sayfa.Block
  alias Sayfa.Content

  @hash_icon ~s(<svg class="icon-3" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24" aria-hidden="true"><line x1="4" x2="20" y1="9" y2="9"/><line x1="4" x2="20" y1="15" y2="15"/><line x1="10" x2="8" y1="3" y2="21"/><line x1="16" x2="14" y1="3" y2="21"/></svg>)

  @impl true
  def name, do: :tag_cloud

  @impl true
  def render(assigns) do
    contents = Map.get(assigns, :contents, [])
    lang = Map.get(assigns, :lang, :en)
    site = Map.get(assigns, :site, %{})

    lang_prefix =
      if Map.has_key?(site, :default_lang) do
        Sayfa.I18n.language_prefix(lang, site)
      else
        ""
      end

    # Filter contents to current language only
    filtered =
      Enum.filter(contents, fn c ->
        (c.meta["lang_prefix"] || "") == lang_prefix
      end)

    tag_groups = Content.group_by_tag(filtered)

    if tag_groups == %{} do
      ""
    else
      max_count = tag_groups |> Map.values() |> Enum.map(&length/1) |> Enum.max(fn -> 1 end)

      items =
        tag_groups
        |> Enum.sort_by(fn {tag, _} -> tag end)
        |> Enum.map_join("\n  ", &render_tag_item(&1, max_count, lang, lang_prefix, site))

      "<section class=\"tag-cloud-wrap\">\n  #{items}\n</section>"
    end
  end

  defp render_tag_item({tag, items}, max_count, lang, lang_prefix, site) do
    count = length(items)
    slug = Slug.slugify(tag)
    classes = size_classes(count, max_count)
    articles_label = Sayfa.I18n.t("articles_count", lang, site, count: count)
    tag_url = tag_url(slug, lang_prefix)

    "<a href=\"#{tag_url}\" class=\"inline-flex items-center gap-1 h-7 px-2.5 rounded-md #{classes}\" title=\"#{Block.escape_html(articles_label)}\">#{@hash_icon} #{Block.escape_html(tag)} <span class=\"cloud-count\">#{count}</span></a>"
  end

  defp tag_url(slug, ""), do: "/tags/#{Block.escape_html(slug)}/"
  defp tag_url(slug, lp), do: "/#{lp}/tags/#{Block.escape_html(slug)}/"

  defp size_classes(count, max_count) when max_count > 0 do
    ratio = count / max_count

    if ratio > 0.6 do
      "cloud-tag-lg"
    else
      "cloud-tag-sm"
    end
  end

  defp size_classes(_, _),
    do: "cloud-tag-sm"
end
