defmodule Sayfa.TemplateTest do
  use ExUnit.Case, async: true

  alias Sayfa.Template
  alias Sayfa.Content

  describe "render_string/2" do
    test "renders EEx with assigns" do
      assert {:ok, "Hello World"} = Template.render_string("Hello <%= @name %>", name: "World")
    end

    test "handles complex assigns" do
      template = "<%= for x <- @items do %><%= x %> <% end %>"
      assert {:ok, result} = Template.render_string(template, items: ["a", "b", "c"])
      assert result =~ "a"
      assert result =~ "b"
      assert result =~ "c"
    end

    test "returns error for invalid template" do
      assert {:error, {:template_render_error, _}} =
               Template.render_string("<%= @missing.field %>", [])
    end
  end

  describe "render_file/2" do
    setup do
      tmp_dir = Path.join(System.tmp_dir!(), "sayfa_tpl_test_#{System.unique_integer([:positive])}")
      File.mkdir_p!(tmp_dir)
      on_exit(fn -> File.rm_rf!(tmp_dir) end)
      {:ok, tmp_dir: tmp_dir}
    end

    test "renders EEx file with assigns", %{tmp_dir: tmp_dir} do
      path = Path.join(tmp_dir, "test.html.eex")
      File.write!(path, "<h1><%= @title %></h1>")

      assert {:ok, "<h1>Hello</h1>"} = Template.render_file(path, title: "Hello")
    end

    test "returns error for missing file", %{tmp_dir: tmp_dir} do
      path = Path.join(tmp_dir, "missing.html.eex")

      assert {:error, {:template_render_error, ^path, _}} = Template.render_file(path, [])
    end
  end

  describe "render_content/2" do
    setup do
      tmp_dir = Path.join(System.tmp_dir!(), "sayfa_tpl_test_#{System.unique_integer([:positive])}")
      layouts_dir = Path.join(tmp_dir, "layouts")
      File.mkdir_p!(layouts_dir)

      # Create minimal layouts for testing
      File.write!(Path.join(layouts_dir, "base.html.eex"), """
      <!DOCTYPE html>
      <html>
      <head><title><%= @page_title %></title></head>
      <body><%= @inner_content %></body>
      </html>
      """)

      File.write!(Path.join(layouts_dir, "post.html.eex"), """
      <article><h1><%= @content.title %></h1><%= @inner_content %></article>
      """)

      File.write!(Path.join(layouts_dir, "page.html.eex"), """
      <div class="page"><%= @inner_content %></div>
      """)

      File.write!(Path.join(layouts_dir, "home.html.eex"), """
      <section class="home"><%= @inner_content %></section>
      """)

      on_exit(fn -> File.rm_rf!(tmp_dir) end)

      config = %{
        title: "Test Site",
        base_url: "http://localhost:4000",
        theme: "default",
        default_lang: :en
      }

      {:ok, layouts_dir: layouts_dir, config: config}
    end

    test "renders content with post layout", %{layouts_dir: layouts_dir, config: config} do
      content = %Content{
        title: "My Post",
        body: "<p>Post body</p>",
        tags: [],
        meta: %{"content_type" => "posts"}
      }

      assert {:ok, html} = Template.render_content(content, config: config, layouts_dir: layouts_dir)
      assert html =~ "<!DOCTYPE html>"
      assert html =~ "<title>My Post</title>"
      assert html =~ "<article>"
      assert html =~ "My Post"
      assert html =~ "Post body"
    end

    test "renders content with page layout by default", %{layouts_dir: layouts_dir, config: config} do
      content = %Content{
        title: "About",
        body: "<p>About page</p>",
        tags: [],
        meta: %{}
      }

      assert {:ok, html} = Template.render_content(content, config: config, layouts_dir: layouts_dir)
      assert html =~ ~s(<div class="page">)
      assert html =~ "About page"
    end

    test "uses layout from front matter", %{layouts_dir: layouts_dir, config: config} do
      content = %Content{
        title: "Home",
        body: "<p>Welcome</p>",
        tags: [],
        meta: %{"layout" => "home"}
      }

      assert {:ok, html} = Template.render_content(content, config: config, layouts_dir: layouts_dir)
      assert html =~ ~s(<section class="home">)
    end

    test "falls back to page layout for unknown layout", %{layouts_dir: layouts_dir, config: config} do
      content = %Content{
        title: "Test",
        body: "<p>Content</p>",
        tags: [],
        meta: %{"layout" => "nonexistent"}
      }

      assert {:ok, html} = Template.render_content(content, config: config, layouts_dir: layouts_dir)
      assert html =~ ~s(<div class="page">)
    end

    test "block stub returns empty string", %{layouts_dir: layouts_dir, config: config} do
      # Add a layout that uses the block function
      File.write!(Path.join(layouts_dir, "with_block.html.eex"), """
      <div><%= @block.(:hero, []) %><%= @inner_content %></div>
      """)

      content = %Content{
        title: "Test",
        body: "<p>Content</p>",
        tags: [],
        meta: %{"layout" => "with_block"}
      }

      assert {:ok, html} = Template.render_content(content, config: config, layouts_dir: layouts_dir)
      assert html =~ "<div>"
      assert html =~ "Content"
    end
  end
end
