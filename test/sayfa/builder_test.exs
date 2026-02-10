defmodule Sayfa.BuilderTest do
  use ExUnit.Case, async: false

  alias Sayfa.Builder

  setup do
    tmp_dir = Path.join(System.tmp_dir!(), "sayfa_builder_#{System.unique_integer([:positive])}")
    content_dir = Path.join(tmp_dir, "content")
    output_dir = Path.join(tmp_dir, "output")
    posts_dir = Path.join(content_dir, "posts")
    pages_dir = Path.join(content_dir, "pages")

    File.mkdir_p!(posts_dir)
    File.mkdir_p!(pages_dir)

    on_exit(fn -> File.rm_rf!(tmp_dir) end)

    {:ok,
     tmp_dir: tmp_dir,
     content_dir: content_dir,
     output_dir: output_dir,
     posts_dir: posts_dir,
     pages_dir: pages_dir}
  end

  defp build_opts(ctx, extra \\ []) do
    [content_dir: ctx.content_dir, output_dir: ctx.output_dir] ++ extra
  end

  describe "build/1" do
    test "builds posts and pages", ctx do
      File.write!(Path.join(ctx.posts_dir, "2024-01-15-hello-world.md"), """
      ---
      title: "Hello World"
      date: 2024-01-15
      tags: [elixir]
      ---

      # Hello World

      This is my first post.
      """)

      File.write!(Path.join(ctx.pages_dir, "about.md"), """
      ---
      title: "About"
      ---

      # About Me

      This is the about page.
      """)

      assert {:ok, result} = Builder.build(build_opts(ctx))
      assert result.files_written == 2
      assert result.content_count == 2
      assert result.elapsed_ms >= 0

      # Verify post output
      post_path = Path.join([ctx.output_dir, "posts", "hello-world", "index.html"])
      assert File.exists?(post_path)
      post_html = File.read!(post_path)
      assert post_html =~ "<!DOCTYPE html>"
      assert post_html =~ "Hello World"
      assert post_html =~ "first post"

      # Verify page output
      page_path = Path.join([ctx.output_dir, "about", "index.html"])
      assert File.exists?(page_path)
      page_html = File.read!(page_path)
      assert page_html =~ "<!DOCTYPE html>"
      assert page_html =~ "About"
    end

    test "filters drafts by default", ctx do
      File.write!(Path.join(ctx.posts_dir, "published.md"), """
      ---
      title: "Published"
      ---
      Content.
      """)

      File.write!(Path.join(ctx.posts_dir, "draft.md"), """
      ---
      title: "Draft Post"
      draft: true
      ---
      Draft content.
      """)

      assert {:ok, result} = Builder.build(build_opts(ctx))
      assert result.files_written == 1
      assert result.content_count == 1
    end

    test "includes drafts when drafts: true", ctx do
      File.write!(Path.join(ctx.posts_dir, "draft.md"), """
      ---
      title: "Draft Post"
      draft: true
      ---
      Draft content.
      """)

      assert {:ok, result} = Builder.build(build_opts(ctx, drafts: true))
      assert result.files_written == 1
      assert result.content_count == 1
    end

    test "returns error for missing content dir", ctx do
      assert {:error, {:content_dir_not_found, _}} =
               Builder.build(content_dir: "/nonexistent", output_dir: ctx.output_dir)
    end

    test "builds with no content files", ctx do
      assert {:ok, result} = Builder.build(build_opts(ctx))
      assert result.files_written == 0
      assert result.content_count == 0
    end

    test "uses layout from front matter", ctx do
      File.write!(Path.join(ctx.pages_dir, "index.md"), """
      ---
      title: "Home"
      layout: home
      ---

      Welcome to my site.
      """)

      assert {:ok, result} = Builder.build(build_opts(ctx))
      assert result.files_written == 1

      # home layout wraps with <section class="home">
      # (default theme layout)
      html = File.read!(Path.join([ctx.output_dir, "index", "index.html"]))
      assert html =~ "<!DOCTYPE html>"
    end

    test "classifies content type from directory structure", ctx do
      notes_dir = Path.join(ctx.content_dir, "notes")
      File.mkdir_p!(notes_dir)

      File.write!(Path.join(notes_dir, "quick-note.md"), """
      ---
      title: "A Quick Note"
      ---
      Short note content.
      """)

      assert {:ok, _result} = Builder.build(build_opts(ctx))

      note_path = Path.join([ctx.output_dir, "notes", "quick-note", "index.html"])
      assert File.exists?(note_path)
    end
  end

  describe "clean/1" do
    test "removes the output directory", ctx do
      File.mkdir_p!(ctx.output_dir)
      File.write!(Path.join(ctx.output_dir, "test.html"), "test")

      assert :ok = Builder.clean(output_dir: ctx.output_dir)
      refute File.exists?(ctx.output_dir)
    end

    test "succeeds even if output dir doesn't exist", ctx do
      assert :ok = Builder.clean(output_dir: ctx.output_dir)
    end
  end
end
