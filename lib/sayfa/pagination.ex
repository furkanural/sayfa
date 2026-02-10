defmodule Sayfa.Pagination do
  @moduledoc """
  Pagination for content lists.

  Splits a list of items into pages and generates URL paths for navigation.
  Page 1 uses the base path directly, page 2+ appends `/page/N/`.

  ## Examples

      pages = Sayfa.Pagination.paginate(posts, page_size: 5, base_path: "/posts")
      first_page = hd(pages)
      first_page.page_number  #=> 1
      first_page.has_next     #=> true
      first_page.next_url     #=> "/posts/page/2/"

  """

  defmodule Page do
    @moduledoc """
    A single page of paginated results.
    """
    defstruct [
      :items,
      :page_number,
      :page_size,
      :total_items,
      :total_pages,
      :has_prev,
      :has_next,
      :prev_url,
      :next_url,
      :url
    ]

    @type t :: %__MODULE__{
            items: [term()],
            page_number: pos_integer(),
            page_size: pos_integer(),
            total_items: non_neg_integer(),
            total_pages: non_neg_integer(),
            has_prev: boolean(),
            has_next: boolean(),
            prev_url: String.t() | nil,
            next_url: String.t() | nil,
            url: String.t()
          }
  end

  @doc """
  Paginates a list of items into `Page` structs.

  ## Options

  - `:page_size` — number of items per page (default: `10`)
  - `:base_path` — URL base path for generating page URLs (default: `"/"`)

  Returns an empty list if items is empty.

  ## Examples

      iex> pages = Sayfa.Pagination.paginate(Enum.to_list(1..25), page_size: 10, base_path: "/posts")
      iex> length(pages)
      3
      iex> hd(pages).page_number
      1
      iex> hd(pages).url
      "/posts/"

  """
  @spec paginate([term()], keyword()) :: [Page.t()]
  def paginate(items, opts \\ [])
  def paginate([], _opts), do: []

  def paginate(items, opts) do
    page_size = Keyword.get(opts, :page_size, 10)
    base_path = Keyword.get(opts, :base_path, "/") |> String.trim_trailing("/")
    total_items = length(items)
    total_pages = ceil(total_items / page_size)

    items
    |> Enum.chunk_every(page_size)
    |> Enum.with_index(1)
    |> Enum.map(fn {chunk, page_num} ->
      %Page{
        items: chunk,
        page_number: page_num,
        page_size: page_size,
        total_items: total_items,
        total_pages: total_pages,
        has_prev: page_num > 1,
        has_next: page_num < total_pages,
        prev_url: prev_url(page_num, base_path),
        next_url: next_url(page_num, total_pages, base_path),
        url: page_url(page_num, base_path)
      }
    end)
  end

  defp page_url(1, base_path), do: "#{base_path}/"
  defp page_url(n, base_path), do: "#{base_path}/page/#{n}/"

  defp prev_url(1, _base_path), do: nil
  defp prev_url(2, base_path), do: "#{base_path}/"
  defp prev_url(n, base_path), do: "#{base_path}/page/#{n - 1}/"

  defp next_url(page_num, total_pages, _base_path) when page_num >= total_pages, do: nil
  defp next_url(page_num, _total_pages, base_path), do: "#{base_path}/page/#{page_num + 1}/"
end
