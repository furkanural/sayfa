defmodule Sayfa.ContentTest do
  use ExUnit.Case, async: true

  alias Sayfa.Content
  alias Sayfa.Content.Raw

  describe "parse/1" do
    test "parses front matter and markdown body" do
      raw = "---\ntitle: Hello\n---\n# World"
      assert {:ok, content} = Content.parse(raw)
      assert content.title == "Hello"
      assert content.body =~ "World"
    end

    test "parses all known front matter fields" do
      raw = """
      ---
      title: "Test Post"
      date: 2024-01-15
      slug: custom-slug
      lang: en
      categories: [elixir, tutorial]
      tags: [test, beginner]
      draft: true
      ---

      # Hello World
      """

      assert {:ok, content} = Content.parse(raw)
      assert content.title == "Test Post"
      assert content.date == ~D[2024-01-15]
      assert content.slug == "custom-slug"
      assert content.lang == :en
      assert content.categories == ["elixir", "tutorial"]
      assert content.tags == ["test", "beginner"]
      assert content.draft == true
    end

    test "puts unknown fields into meta" do
      raw = """
      ---
      title: Post
      custom_field: custom value
      featured: true
      image: /images/cover.jpg
      ---

      Content here.
      """

      assert {:ok, content} = Content.parse(raw)
      assert content.meta["custom_field"] == "custom value"
      assert content.meta["featured"] == true
      assert content.meta["image"] == "/images/cover.jpg"
    end

    test "returns error for missing front matter" do
      assert {:error, :missing_front_matter} = Content.parse("# Just markdown")
    end

    test "returns error for missing title" do
      raw = "---\ndate: 2024-01-15\n---\n# Content"
      assert {:error, :missing_title} = Content.parse(raw)
    end

    test "defaults draft to false" do
      raw = "---\ntitle: Test\n---\nContent"
      assert {:ok, content} = Content.parse(raw)
      assert content.draft == false
    end

    test "defaults categories and tags to empty lists" do
      raw = "---\ntitle: Test\n---\nContent"
      assert {:ok, content} = Content.parse(raw)
      assert content.categories == []
      assert content.tags == []
    end

    test "renders markdown to HTML in body" do
      raw = "---\ntitle: Test\n---\n# Heading\n\n**bold** text"
      assert {:ok, content} = Content.parse(raw)
      assert content.body =~ "<h1>"
      assert content.body =~ "<strong>bold</strong>"
    end
  end

  describe "parse!/1" do
    test "returns content directly" do
      raw = "---\ntitle: Test\n---\n# Hello"
      content = Content.parse!(raw)
      assert content.title == "Test"
    end

    test "raises on error" do
      assert_raise RuntimeError, ~r/Content parsing failed/, fn ->
        Content.parse!("no front matter")
      end
    end
  end

  describe "parse_file/1" do
    setup do
      tmp_dir = Path.join(System.tmp_dir!(), "sayfa_test_#{System.unique_integer([:positive])}")
      File.mkdir_p!(tmp_dir)
      on_exit(fn -> File.rm_rf!(tmp_dir) end)
      {:ok, tmp_dir: tmp_dir}
    end

    test "reads and parses a file", %{tmp_dir: tmp_dir} do
      path = Path.join(tmp_dir, "2024-01-15-hello-world.md")
      File.write!(path, "---\ntitle: Hello World\n---\n# Hello")

      assert {:ok, content} = Content.parse_file(path)
      assert content.title == "Hello World"
      assert content.source_path == path
      assert content.slug == "hello-world"
    end

    test "generates slug from filename without date prefix", %{tmp_dir: tmp_dir} do
      path = Path.join(tmp_dir, "about.md")
      File.write!(path, "---\ntitle: About\n---\nAbout page")

      assert {:ok, content} = Content.parse_file(path)
      assert content.slug == "about"
    end

    test "uses slug from front matter over filename", %{tmp_dir: tmp_dir} do
      path = Path.join(tmp_dir, "2024-01-15-old-slug.md")
      File.write!(path, "---\ntitle: Test\nslug: custom-slug\n---\nContent")

      assert {:ok, content} = Content.parse_file(path)
      assert content.slug == "custom-slug"
    end

    test "returns error for missing file" do
      assert {:error, {:file_read_error, _, :enoent}} = Content.parse_file("/nonexistent.md")
    end
  end

  describe "from_raw/1" do
    test "transforms Raw struct into Content" do
      raw = %Raw{
        path: "content/posts/2024-01-15-hello.md",
        front_matter: %{"title" => "Hello", "tags" => ["elixir"]},
        body_markdown: "# World",
        filename: "2024-01-15-hello.md"
      }

      assert {:ok, content} = Content.from_raw(raw)
      assert content.title == "Hello"
      assert content.body =~ "World"
      assert content.tags == ["elixir"]
      assert content.source_path == "content/posts/2024-01-15-hello.md"
      assert content.slug == "hello"
    end

    test "returns error for missing title in Raw" do
      raw = %Raw{
        path: "test.md",
        front_matter: %{"date" => ~D[2024-01-15]},
        body_markdown: "# Content"
      }

      assert {:error, :missing_title} = Content.from_raw(raw)
    end
  end

  describe "slug_from_filename/1" do
    test "strips date prefix" do
      assert Content.slug_from_filename("2024-01-15-hello-world.md") == "hello-world"
    end

    test "handles filenames without date prefix" do
      assert Content.slug_from_filename("about.md") == "about"
    end

    test "returns nil for nil input" do
      assert Content.slug_from_filename(nil) == nil
    end

    test "handles multiple extensions" do
      assert Content.slug_from_filename("2024-01-15-post.html.md") == "post.html"
    end
  end

  describe "url/1" do
    test "builds URL with url_prefix" do
      content =
        make_content(%{slug: "hello", meta: %{"url_prefix" => "posts", "lang_prefix" => ""}})

      assert Content.url(content) == "/posts/hello"
    end

    test "builds URL with lang_prefix" do
      content =
        make_content(%{slug: "merhaba", meta: %{"url_prefix" => "posts", "lang_prefix" => "tr"}})

      assert Content.url(content) == "/tr/posts/merhaba"
    end

    test "builds URL for pages (empty url_prefix)" do
      content = make_content(%{slug: "about", meta: %{"url_prefix" => "", "lang_prefix" => ""}})
      assert Content.url(content) == "/about"
    end

    test "builds URL for index slug" do
      content = make_content(%{slug: "index", meta: %{"url_prefix" => "", "lang_prefix" => ""}})
      assert Content.url(content) == "/"
    end

    test "builds URL for index with prefix" do
      content =
        make_content(%{slug: "index", meta: %{"url_prefix" => "posts", "lang_prefix" => ""}})

      assert Content.url(content) == "/posts"
    end

    test "builds URL for index with lang_prefix" do
      content = make_content(%{slug: "index", meta: %{"url_prefix" => "", "lang_prefix" => "tr"}})
      assert Content.url(content) == "/tr/"
    end

    test "handles nil lang_prefix and url_prefix" do
      content = make_content(%{slug: "hello", meta: %{}})
      assert Content.url(content) == "/hello"
    end
  end

  # --- Collections API Tests ---

  defp make_content(attrs) do
    defaults = %{
      title: "default",
      body: "<p>test</p>",
      tags: [],
      categories: [],
      meta: %{},
      date: nil
    }

    Map.merge(defaults, attrs) |> then(&struct!(Content, &1))
  end

  describe "all_of_type/2" do
    test "filters by content_type in meta" do
      contents = [
        make_content(%{title: "Post", meta: %{"content_type" => "posts"}}),
        make_content(%{title: "Page", meta: %{"content_type" => "pages"}}),
        make_content(%{title: "Post 2", meta: %{"content_type" => "posts"}})
      ]

      result = Content.all_of_type(contents, "posts")
      assert length(result) == 2
      assert Enum.all?(result, fn c -> c.meta["content_type"] == "posts" end)
    end

    test "returns empty list when no match" do
      contents = [make_content(%{title: "Post", meta: %{"content_type" => "posts"}})]
      assert Content.all_of_type(contents, "notes") == []
    end
  end

  describe "with_tag/2" do
    test "filters by tag" do
      contents = [
        make_content(%{title: "A", tags: ["elixir", "otp"]}),
        make_content(%{title: "B", tags: ["rust"]}),
        make_content(%{title: "C", tags: ["elixir"]})
      ]

      result = Content.with_tag(contents, "elixir")
      assert length(result) == 2
      assert Enum.map(result, & &1.title) == ["A", "C"]
    end
  end

  describe "with_category/2" do
    test "filters by category" do
      contents = [
        make_content(%{title: "A", categories: ["programming"]}),
        make_content(%{title: "B", categories: ["cooking"]}),
        make_content(%{title: "C", categories: ["programming", "elixir"]})
      ]

      result = Content.with_category(contents, "programming")
      assert length(result) == 2
    end
  end

  describe "sort_by_date/2" do
    test "sorts descending by default" do
      contents = [
        make_content(%{title: "Old", date: ~D[2024-01-01]}),
        make_content(%{title: "New", date: ~D[2024-06-01]}),
        make_content(%{title: "Mid", date: ~D[2024-03-01]})
      ]

      result = Content.sort_by_date(contents)
      assert Enum.map(result, & &1.title) == ["New", "Mid", "Old"]
    end

    test "sorts ascending when specified" do
      contents = [
        make_content(%{title: "Old", date: ~D[2024-01-01]}),
        make_content(%{title: "New", date: ~D[2024-06-01]})
      ]

      result = Content.sort_by_date(contents, :asc)
      assert Enum.map(result, & &1.title) == ["Old", "New"]
    end

    test "pushes nil dates to end" do
      contents = [
        make_content(%{title: "No Date"}),
        make_content(%{title: "Has Date", date: ~D[2024-01-01]})
      ]

      result = Content.sort_by_date(contents)
      assert Enum.map(result, & &1.title) == ["Has Date", "No Date"]
    end
  end

  describe "recent/2" do
    test "returns N most recent items" do
      contents = [
        make_content(%{title: "A", date: ~D[2024-01-01]}),
        make_content(%{title: "B", date: ~D[2024-06-01]}),
        make_content(%{title: "C", date: ~D[2024-03-01]})
      ]

      result = Content.recent(contents, 2)
      assert Enum.map(result, & &1.title) == ["B", "C"]
    end

    test "returns all items when n > length" do
      contents = [make_content(%{title: "A", date: ~D[2024-01-01]})]
      assert length(Content.recent(contents, 5)) == 1
    end
  end

  describe "group_by_tag/1" do
    test "groups contents by their tags" do
      contents = [
        make_content(%{title: "A", tags: ["elixir", "otp"]}),
        make_content(%{title: "B", tags: ["elixir"]}),
        make_content(%{title: "C", tags: ["rust"]})
      ]

      groups = Content.group_by_tag(contents)
      assert length(groups["elixir"]) == 2
      assert length(groups["otp"]) == 1
      assert length(groups["rust"]) == 1
    end

    test "returns empty map for no tags" do
      contents = [make_content(%{title: "A", tags: []})]
      assert Content.group_by_tag(contents) == %{}
    end

    test "preserves order within groups" do
      contents = [
        make_content(%{title: "First", tags: ["elixir"]}),
        make_content(%{title: "Second", tags: ["elixir"]})
      ]

      groups = Content.group_by_tag(contents)
      assert Enum.map(groups["elixir"], & &1.title) == ["First", "Second"]
    end
  end

  describe "group_by_category/1" do
    test "groups contents by their categories" do
      contents = [
        make_content(%{title: "A", categories: ["programming"]}),
        make_content(%{title: "B", categories: ["programming", "elixir"]}),
        make_content(%{title: "C", categories: ["cooking"]})
      ]

      groups = Content.group_by_category(contents)
      assert length(groups["programming"]) == 2
      assert length(groups["elixir"]) == 1
      assert length(groups["cooking"]) == 1
    end

    test "returns empty map for no categories" do
      contents = [make_content(%{title: "A", categories: []})]
      assert Content.group_by_category(contents) == %{}
    end
  end
end
