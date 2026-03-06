defmodule Sayfa.Blocks.RecentContentTest do
  use ExUnit.Case, async: true

  alias Sayfa.Blocks.RecentContent

  defp make_content(title, type, date, slug \\ nil) do
    %Sayfa.Content{
      title: title,
      body: "<p>#{title}</p>",
      date: date,
      slug: slug || Slug.slugify(title),
      meta: %{"content_type" => type, "url_prefix" => type}
    }
  end

  describe "name/0" do
    test "returns :recent_content" do
      assert RecentContent.name() == :recent_content
    end
  end

  describe "render/1" do
    test "renders sections for multiple content types" do
      contents = [
        make_content("Article One", "articles", ~D[2024-06-01]),
        make_content("Note One", "notes", ~D[2024-05-01]),
        make_content("Article Two", "articles", ~D[2024-04-01])
      ]

      result = RecentContent.render(%{contents: contents, limit: 5})

      assert result =~ "Articles"
      assert result =~ "Notes"
      assert result =~ "Article One"
      assert result =~ "Note One"
      assert result =~ "Article Two"
    end

    test "returns empty string when no content" do
      assert RecentContent.render(%{contents: []}) == ""
    end

    test "returns empty string when only pages" do
      contents = [
        make_content("Home", "pages", nil)
      ]

      assert RecentContent.render(%{contents: contents}) == ""
    end

    test "respects limit option" do
      contents = [
        make_content("Article One", "articles", ~D[2024-06-01]),
        make_content("Article Two", "articles", ~D[2024-05-01]),
        make_content("Article Three", "articles", ~D[2024-04-01])
      ]

      result = RecentContent.render(%{contents: contents, limit: 1})

      assert result =~ "Article One"
      refute result =~ "Article Two"
      refute result =~ "Article Three"
    end

    test "includes lang_prefix in URLs" do
      contents = [
        %Sayfa.Content{
          title: "Merhaba",
          body: "<p>Merhaba</p>",
          date: ~D[2024-06-01],
          slug: "merhaba",
          meta: %{"content_type" => "articles", "url_prefix" => "articles", "lang_prefix" => "tr"}
        }
      ]

      result = RecentContent.render(%{contents: contents, limit: 5})

      assert result =~ "/tr/articles/merhaba"
      assert result =~ "Merhaba"
    end

    test "excludes pages type" do
      contents = [
        make_content("Article One", "articles", ~D[2024-06-01]),
        make_content("Home", "pages", nil)
      ]

      result = RecentContent.render(%{contents: contents, limit: 5})

      assert result =~ "Article One"
      refute result =~ "Pages"
    end

    test "renders view all links" do
      contents = [
        make_content("Article One", "articles", ~D[2024-06-01])
      ]

      result = RecentContent.render(%{contents: contents, limit: 5})

      assert result =~ "View all"
      assert result =~ "/articles/"
    end
  end
end
