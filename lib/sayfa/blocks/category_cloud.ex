defmodule Sayfa.Blocks.CategoryCloud do
  @moduledoc """
  Category cloud block.

  Renders a flex-wrap section with category pills sized by frequency,
  each prefixed with a folder icon.

  ## Assigns

  - `:contents` — list of all site contents (injected by block helper)

  ## Examples

      <%= @block.(:category_cloud) %>

  """

  @behaviour Sayfa.Behaviours.Block

  alias Sayfa.Block
  alias Sayfa.Content

  @folder_icon ~s(<svg class="w-3 h-3" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24" aria-hidden="true"><path d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z"/></svg>)

  @impl true
  def name, do: :category_cloud

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

    cat_groups = Content.group_by_category(filtered)

    if cat_groups == %{} do
      ""
    else
      max_count = cat_groups |> Map.values() |> Enum.map(&length/1) |> Enum.max(fn -> 1 end)

      items =
        cat_groups
        |> Enum.sort_by(fn {cat, _} -> cat end)
        |> Enum.map_join("\n  ", &render_category_item(&1, max_count, lang, lang_prefix, site))

      "<section class=\"flex flex-wrap gap-2\">\n  #{items}\n</section>"
    end
  end

  defp render_category_item({category, items}, max_count, lang, lang_prefix, site) do
    count = length(items)
    slug = Slug.slugify(category)
    classes = size_classes(count, max_count)
    posts_label = Sayfa.I18n.t("posts_count", lang, site, count: count)
    cat_url = category_url(slug, lang_prefix)

    "<a href=\"#{cat_url}\" class=\"inline-flex items-center gap-1 h-7 px-2.5 rounded-md #{classes}\" title=\"#{Block.escape_html(posts_label)}\">#{@folder_icon} #{Block.escape_html(category)} <span class=\"ml-0.5 text-xs opacity-60\">#{count}</span></a>"
  end

  defp category_url(slug, ""), do: "/categories/#{Block.escape_html(slug)}/"
  defp category_url(slug, lp), do: "/#{lp}/categories/#{Block.escape_html(slug)}/"

  defp size_classes(count, max_count) when max_count > 0 do
    ratio = count / max_count

    if ratio > 0.6 do
      "text-sm font-medium bg-amber-50 text-amber-700 dark:bg-amber-900/20 dark:text-amber-400 hover:bg-amber-100 dark:hover:bg-amber-900/40"
    else
      "text-xs font-medium bg-amber-50/50 text-amber-600 dark:bg-amber-900/10 dark:text-amber-400/80 hover:bg-amber-50 hover:text-amber-700 dark:hover:bg-amber-900/20 dark:hover:text-amber-400"
    end
  end

  defp size_classes(_, _),
    do:
      "text-xs font-medium bg-amber-50/50 text-amber-600 dark:bg-amber-900/10 dark:text-amber-400/80 hover:bg-amber-50 hover:text-amber-700 dark:hover:bg-amber-900/20 dark:hover:text-amber-400"
end
