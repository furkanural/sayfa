defmodule Sayfa.PaginationTest do
  use ExUnit.Case, async: true

  alias Sayfa.Pagination

  describe "paginate/2" do
    test "returns empty list for empty input" do
      assert Pagination.paginate([]) == []
    end

    test "returns single page when items fit" do
      pages = Pagination.paginate([1, 2, 3], page_size: 10, base_path: "/posts")
      assert length(pages) == 1

      page = hd(pages)
      assert page.items == [1, 2, 3]
      assert page.page_number == 1
      assert page.page_size == 10
      assert page.total_items == 3
      assert page.total_pages == 1
      assert page.has_prev == false
      assert page.has_next == false
      assert page.prev_url == nil
      assert page.next_url == nil
      assert page.url == "/posts/"
    end

    test "splits items across pages" do
      pages = Pagination.paginate(Enum.to_list(1..5), page_size: 2, base_path: "/posts")
      assert length(pages) == 3

      [p1, p2, p3] = pages
      assert p1.items == [1, 2]
      assert p2.items == [3, 4]
      assert p3.items == [5]
    end

    test "generates correct page numbers" do
      pages = Pagination.paginate(Enum.to_list(1..10), page_size: 3, base_path: "/posts")

      assert Enum.map(pages, & &1.page_number) == [1, 2, 3, 4]
    end

    test "sets total_items and total_pages" do
      pages = Pagination.paginate(Enum.to_list(1..7), page_size: 3, base_path: "/posts")

      for page <- pages do
        assert page.total_items == 7
        assert page.total_pages == 3
      end
    end

    test "sets has_prev and has_next correctly" do
      [p1, p2, p3] = Pagination.paginate(Enum.to_list(1..6), page_size: 2, base_path: "/x")

      assert p1.has_prev == false
      assert p1.has_next == true

      assert p2.has_prev == true
      assert p2.has_next == true

      assert p3.has_prev == true
      assert p3.has_next == false
    end
  end

  describe "URL generation" do
    test "page 1 uses base path" do
      [page] = Pagination.paginate([1], page_size: 10, base_path: "/posts")
      assert page.url == "/posts/"
    end

    test "page 2+ uses /page/N/ suffix" do
      [_p1, p2, p3] = Pagination.paginate(Enum.to_list(1..6), page_size: 2, base_path: "/posts")

      assert p2.url == "/posts/page/2/"
      assert p3.url == "/posts/page/3/"
    end

    test "prev_url for page 1 is nil" do
      [p1 | _] = Pagination.paginate(Enum.to_list(1..5), page_size: 2, base_path: "/posts")
      assert p1.prev_url == nil
    end

    test "prev_url for page 2 points to base path" do
      [_p1, p2 | _] = Pagination.paginate(Enum.to_list(1..5), page_size: 2, base_path: "/posts")
      assert p2.prev_url == "/posts/"
    end

    test "prev_url for page 3+ uses /page/N/" do
      [_, _, p3] = Pagination.paginate(Enum.to_list(1..6), page_size: 2, base_path: "/posts")
      assert p3.prev_url == "/posts/page/2/"
    end

    test "next_url for last page is nil" do
      pages = Pagination.paginate(Enum.to_list(1..3), page_size: 2, base_path: "/posts")
      last = List.last(pages)
      assert last.next_url == nil
    end

    test "next_url for first page points to page 2" do
      [p1 | _] = Pagination.paginate(Enum.to_list(1..5), page_size: 2, base_path: "/posts")
      assert p1.next_url == "/posts/page/2/"
    end

    test "uses default page_size of 10" do
      pages = Pagination.paginate(Enum.to_list(1..25), base_path: "/posts")
      assert length(pages) == 3
      assert hd(pages).page_size == 10
    end

    test "strips trailing slash from base_path" do
      [page] = Pagination.paginate([1], page_size: 10, base_path: "/posts/")
      assert page.url == "/posts/"
    end
  end
end
