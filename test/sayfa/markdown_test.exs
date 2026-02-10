defmodule Sayfa.MarkdownTest do
  use ExUnit.Case, async: true
  doctest Sayfa.Markdown

  describe "render/1" do
    test "renders heading" do
      assert {:ok, "<h1>Hello</h1>"} = Sayfa.Markdown.render("# Hello")
    end

    test "renders inline formatting" do
      assert {:ok, html} = Sayfa.Markdown.render("**bold** and *italic*")
      assert html =~ "<strong>bold</strong>"
      assert html =~ "<em>italic</em>"
    end

    test "renders code blocks with syntax highlighting" do
      assert {:ok, html} = Sayfa.Markdown.render("```elixir\nIO.puts(1)\n```")
      assert html =~ "language-elixir"
    end

    test "renders strikethrough" do
      assert {:ok, html} = Sayfa.Markdown.render("~~deleted~~")
      assert html =~ "<del>deleted</del>"
    end

    test "renders tables" do
      markdown = """
      | A | B |
      |---|---|
      | 1 | 2 |
      """

      assert {:ok, html} = Sayfa.Markdown.render(markdown)
      assert html =~ "<table>"
    end

    test "renders empty string" do
      assert {:ok, ""} = Sayfa.Markdown.render("")
    end
  end

  describe "render!/1" do
    test "returns HTML directly" do
      assert "<h1>Hello</h1>" = Sayfa.Markdown.render!("# Hello")
    end
  end
end
