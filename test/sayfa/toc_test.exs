defmodule Sayfa.TOCTest do
  use ExUnit.Case, async: true
  doctest Sayfa.TOC

  alias Sayfa.TOC

  describe "extract/1" do
    test "extracts h2-h6 headings" do
      html = """
      <h2><a href="#intro" aria-hidden="true" class="anchor" id="intro"></a>Introduction</h2>
      <p>Some text</p>
      <h3><a href="#details" aria-hidden="true" class="anchor" id="details"></a>Details</h3>
      <p>More text</p>
      <h4><a href="#sub" aria-hidden="true" class="anchor" id="sub"></a>Sub-section</h4>
      """

      result = TOC.extract(html)

      assert [
               %{level: 2, text: "Introduction", id: "intro"},
               %{level: 3, text: "Details", id: "details"},
               %{level: 4, text: "Sub-section", id: "sub"}
             ] = result
    end

    test "skips h1 headings" do
      html = """
      <h1><a href="#title" aria-hidden="true" class="anchor" id="title"></a>Title</h1>
      <h2><a href="#intro" aria-hidden="true" class="anchor" id="intro"></a>Introduction</h2>
      """

      result = TOC.extract(html)
      assert length(result) == 1
      assert hd(result).text == "Introduction"
    end

    test "handles inline tags in heading text" do
      html =
        ~s(<h2><a href="#code" aria-hidden="true" class="anchor" id="code"></a>Using <code>IO.puts</code></h2>)

      result = TOC.extract(html)
      assert [%{text: "Using IO.puts", id: "code"}] = result
    end

    test "returns empty list for no headings" do
      assert TOC.extract("<p>No headings here</p>") == []
    end

    test "returns empty list for empty string" do
      assert TOC.extract("") == []
    end

    test "works with actual MDEx output" do
      {:ok, html} = Sayfa.Markdown.render("## Getting Started\n\n### Installation")
      result = TOC.extract(html)

      assert length(result) == 2
      assert hd(result).text == "Getting Started"
      assert hd(result).level == 2
    end
  end
end
