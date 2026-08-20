defmodule Sayfa.TOCTest do
  use ExUnit.Case, async: true
  doctest Sayfa.TOC

  alias Sayfa.TOC

  describe "extract/1" do
    test "extracts h2-h6 headings" do
      html = """
      <h2 id="intro">Introduction<a href="#intro" aria-label="Link to heading 'Introduction'" data-heading-content="Introduction" class="anchor"></a></h2>
      <p>Some text</p>
      <h3 id="details">Details<a href="#details" aria-label="Link to heading 'Details'" data-heading-content="Details" class="anchor"></a></h3>
      <p>More text</p>
      <h4 id="sub">Sub-section<a href="#sub" aria-label="Link to heading 'Sub-section'" data-heading-content="Sub-section" class="anchor"></a></h4>
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
      <h1 id="title">Title<a href="#title" aria-label="Link to heading 'Title'" data-heading-content="Title" class="anchor"></a></h1>
      <h2 id="intro">Introduction<a href="#intro" aria-label="Link to heading 'Introduction'" data-heading-content="Introduction" class="anchor"></a></h2>
      """

      result = TOC.extract(html)
      assert length(result) == 1
      assert hd(result).text == "Introduction"
    end

    test "handles inline tags in heading text" do
      html =
        ~s(<h2 id="code">Using <code>IO.puts</code><a href="#code" aria-label="Link to heading 'Using IO.puts'" data-heading-content="Using IO.puts" class="anchor"></a></h2>)

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
