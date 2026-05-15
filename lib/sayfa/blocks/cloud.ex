defmodule Sayfa.Blocks.Cloud do
  @moduledoc """
  Shared implementation for tag and category clouds.

  Both clouds follow the exact same rendering pipeline; only the data source
  (tags vs categories), icon, URL prefix, and CSS class prefix differ.
  """

  alias Sayfa.Block
  alias Sayfa.Content
  alias Sayfa.I18n

  @hash_icon ~s(<svg class="icon-3" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24" aria-hidden="true"><line x1="4" x2="20" y1="9" y2="9"/><line x1="4" x2="20" y1="15" y2="15"/><line x1="10" x2="8" y1="3" y2="21"/><line x1="16" x2="14" y1="3" y2="21"/></svg>)

  @folder_icon ~s(<svg class="icon-3" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24" aria-hidden="true"><path d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z"/></svg>)

  @type cloud_type :: :tag | :category

  @doc """
  Renders a cloud of tags or categories.

  ## Options

  - `:type` — `:tag` or `:category` (required)
  - `:contents` — list of all site contents
  - `:lang` — current language
  - `:site` — site config
  """
  @spec render(map(), cloud_type()) :: String.t()
  def render(assigns, type) do
    contents = Map.get(assigns, :contents, [])
    lang = Map.get(assigns, :lang, :en)
    site = Map.get(assigns, :site, %{})

    lang_prefix =
      if Map.has_key?(site, :default_lang) do
        I18n.language_prefix(lang, site)
      else
        ""
      end

    filtered =
      Enum.filter(contents, fn c ->
        (c.meta["lang_prefix"] || "") == lang_prefix
      end)

    groups = group_contents(filtered, type)

    if groups == %{} do
      ""
    else
      max_count = groups |> Map.values() |> Enum.map(&length/1) |> Enum.max(fn -> 1 end)

      items =
        groups
        |> Enum.sort_by(fn {name, _} -> name end)
        |> Enum.map_join("\n  ", &render_item(&1, max_count, lang, lang_prefix, site, type))

      wrapper_class = if type == :tag, do: "tag-cloud-wrap", else: "category-cloud-wrap"
      "<section class=\"#{wrapper_class}\">\n  #{items}\n</section>"
    end
  end

  defp group_contents(contents, :tag), do: Content.group_by_tag(contents)
  defp group_contents(contents, :category), do: Content.group_by_category(contents)

  defp render_item({name, items}, max_count, lang, lang_prefix, site, type) do
    count = length(items)
    slug = Slug.slugify(name)
    classes = size_classes(count, max_count, type)
    label = I18n.t("articles_count", lang, site, count: count)
    url = build_url(type, slug, lang_prefix)
    icon = if type == :tag, do: @hash_icon, else: @folder_icon

    "<a href=\"#{url}\" class=\"#{classes}\" title=\"#{Block.escape_html(label)}\">#{icon} #{Block.escape_html(name)} <span class=\"cloud-count\">#{count}</span></a>"
  end

  defp build_url(:tag, slug, ""), do: "/tags/#{Block.escape_html(slug)}/"
  defp build_url(:tag, slug, lp), do: "/#{lp}/tags/#{Block.escape_html(slug)}/"
  defp build_url(:category, slug, ""), do: "/categories/#{Block.escape_html(slug)}/"
  defp build_url(:category, slug, lp), do: "/#{lp}/categories/#{Block.escape_html(slug)}/"

  defp size_classes(count, max_count, type) when max_count > 0 do
    prefix = if type == :tag, do: "cloud-tag", else: "cloud-category"
    ratio = count / max_count

    if ratio > 0.6 do
      "#{prefix}-lg"
    else
      "#{prefix}-sm"
    end
  end

  defp size_classes(_, _, type) do
    prefix = if type == :tag, do: "cloud-tag", else: "cloud-category"
    "#{prefix}-sm"
  end
end
