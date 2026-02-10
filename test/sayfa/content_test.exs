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
end
