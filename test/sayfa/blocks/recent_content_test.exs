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
        make_content("Post One", "posts", ~D[2024-06-01]),
        make_content("Note One", "notes", ~D[2024-05-01]),
        make_content("Post Two", "posts", ~D[2024-04-01])
      ]

      result = RecentContent.render(%{contents: contents, limit: 5})

      assert result =~ "Posts"
      assert result =~ "Notes"
      assert result =~ "Post One"
      assert result =~ "Note One"
      assert result =~ "Post Two"
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
        make_content("Post One", "posts", ~D[2024-06-01]),
        make_content("Post Two", "posts", ~D[2024-05-01]),
        make_content("Post Three", "posts", ~D[2024-04-01])
      ]

      result = RecentContent.render(%{contents: contents, limit: 1})

      assert result =~ "Post One"
      refute result =~ "Post Two"
      refute result =~ "Post Three"
    end

    test "includes lang_prefix in URLs" do
      contents = [
        %Sayfa.Content{
          title: "Merhaba",
          body: "<p>Merhaba</p>",
          date: ~D[2024-06-01],
          slug: "merhaba",
          meta: %{"content_type" => "posts", "url_prefix" => "posts", "lang_prefix" => "tr"}
        }
      ]

      result = RecentContent.render(%{contents: contents, limit: 5})

      assert result =~ "/tr/posts/merhaba"
      assert result =~ "Merhaba"
    end

    test "excludes pages type" do
      contents = [
        make_content("Post One", "posts", ~D[2024-06-01]),
        make_content("Home", "pages", nil)
      ]

      result = RecentContent.render(%{contents: contents, limit: 5})

      assert result =~ "Post One"
      refute result =~ "Pages"
    end

    test "renders view all links" do
      contents = [
        make_content("Post One", "posts", ~D[2024-06-01])
      ]

      result = RecentContent.render(%{contents: contents, limit: 5})

      assert result =~ "View all"
      assert result =~ "/posts/"
    end
  end
end
