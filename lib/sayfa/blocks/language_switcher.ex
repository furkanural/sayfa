defmodule Sayfa.Blocks.LanguageSwitcher do
  @moduledoc """
  Language switcher block.

  Renders links to translations of the current page. Returns `""` if only
  one language is configured. Uses `hreflang_alternates` from content metadata
  for content pages, and constructs alternate URLs from language config for
  list/index pages.

  ## Assigns

  - `:site` — site config map (used for languages)
  - `:content` — current `Sayfa.Content` struct (nil on list/home pages)
  - `:lang` — current language atom
  - `:page_url` — current page URL (for list pages)
  - `:variant` — optional atom (`:desktop`, `:mobile`, or `:default`) for unique IDs (default: `:default`)

  ## Examples

      <%= @block.(:language_switcher, []) %>
      <%= @block.(:language_switcher, variant: :desktop) %>
      <%= @block.(:language_switcher, variant: :mobile) %>

  """

  @behaviour Sayfa.Behaviours.Block

  alias Sayfa.Block

  @impl true
  def name, do: :language_switcher

  @impl true
  def render(assigns) do
    site = Map.get(assigns, :site, %{})
    languages = Map.get(site, :languages, [])

    if length(languages) <= 1 do
      ""
    else
      content = Map.get(assigns, :content)
      current_lang = Map.get(assigns, :lang, Map.get(site, :default_lang, :en))
      variant = Map.get(assigns, :variant, :default)

      alternates = build_alternates(content, assigns, languages, current_lang, site)
      render_switcher(alternates, current_lang, languages, variant)
    end
  end

  defp build_alternates(content, _assigns, _languages, current_lang, _site)
       when not is_nil(content) do
    case content.meta["hreflang_alternates"] do
      alternates when is_list(alternates) and alternates != [] ->
        Map.new(alternates, fn {lang_str, url} -> {String.to_atom(lang_str), url} end)

      _ ->
        # No verified translations — only include current language so switcher hides
        %{current_lang => Sayfa.Content.url(content)}
    end
  end

  defp build_alternates(nil, assigns, languages, current_lang, site) do
    case Map.get(assigns, :archive_alternates) do
      alternates when is_map(alternates) and map_size(alternates) > 0 ->
        alternates

      _ ->
        page_url = Map.get(assigns, :page_url)

        if page_url do
          construct_url_alternates(page_url, languages, current_lang, site)
        else
          %{}
        end
    end
  end

  defp construct_url_alternates(page_url, languages, current_lang, site) do
    default_lang = Map.get(site, :default_lang, :en)

    Map.new(Keyword.keys(languages), fn lang ->
      url = construct_alternate_url(page_url, lang, current_lang, default_lang)
      {lang, url}
    end)
  end

  defp construct_alternate_url(page_url, target_lang, current_lang, default_lang) do
    stripped =
      if current_lang != default_lang do
        prefix = "/#{current_lang}/"

        if String.starts_with?(page_url, prefix) do
          "/" <> String.trim_leading(page_url, prefix)
        else
          page_url
        end
      else
        page_url
      end

    if target_lang == default_lang do
      stripped
    else
      "/#{target_lang}#{stripped}"
    end
  end

  defp render_switcher(alternates, _current_lang, _languages, _variant)
       when map_size(alternates) <= 1,
       do: ""

  defp render_switcher(alternates, current_lang, languages, variant) do
    items =
      languages
      |> Keyword.keys()
      |> Enum.map(fn lang ->
        case Map.get(alternates, lang) do
          nil -> nil
          url -> {lang, get_language_name(lang, languages), url}
        end
      end)
      |> Enum.reject(&is_nil/1)

    if length(items) <= 1 do
      ""
    else
      render_dropdown(items, current_lang, variant)
    end
  end

  defp render_dropdown(items, current_lang, variant) do
    current_code = current_lang |> to_string() |> String.upcase()
    dropdown_items = Enum.map_join(items, "", &render_dropdown_item(&1, current_lang))

    # Generate unique IDs based on variant
    id_suffix = if variant == :default, do: "", else: "-#{variant}"
    switcher_id = "lang-switcher#{id_suffix}"
    toggle_id = "lang-toggle#{id_suffix}"
    menu_id = "lang-menu#{id_suffix}"

    globe_svg =
      ~s(<svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="10"/><path d="M2 12h20M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/></svg>)

    chevron_svg =
      ~s(<svg class="w-3 h-3 transition-transform" aria-hidden="true" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="m6 9 6 6 6-6"/></svg>)

    ~s(<div class="relative" id="#{switcher_id}">) <>
      ~s(<button id="#{toggle_id}" class="flex items-center gap-1.5 p-2 text-sm text-slate-500 dark:text-slate-400 hover:text-slate-900 dark:hover:text-slate-100 transition-colors" aria-expanded="false" aria-haspopup="listbox" aria-label="Language">) <>
      globe_svg <>
      ~s(<span class="text-xs font-medium">#{current_code}</span>) <>
      chevron_svg <>
      ~s(</button>) <>
      ~s(<div id="#{menu_id}" class="hidden absolute right-0 mt-1 min-w-[8rem] py-1 rounded-lg border border-slate-200/80 dark:border-slate-700 bg-white/90 dark:bg-slate-900/90 backdrop-blur-lg shadow-lg" role="listbox" aria-label="Language">) <>
      dropdown_items <>
      ~s(</div>) <>
      ~s(</div>)
  end

  defp render_dropdown_item({lang, lang_name, _url}, lang) do
    ~s(<span class="block px-3 py-2 text-sm font-medium text-slate-900 dark:text-slate-100">#{Block.escape_html(lang_name)}</span>)
  end

  defp render_dropdown_item({_lang, lang_name, url}, _current_lang) do
    ~s(<a href="#{Block.escape_html(url)}" class="block px-3 py-2 text-sm text-slate-600 dark:text-slate-300 hover:text-primary dark:hover:text-primary-400 hover:bg-slate-50 dark:hover:bg-slate-800/50">#{Block.escape_html(lang_name)}</a>)
  end

  defp get_language_name(lang, languages) do
    languages
    |> Keyword.get(lang, [])
    |> Keyword.get(:name, lang |> to_string() |> String.upcase())
  end
end
