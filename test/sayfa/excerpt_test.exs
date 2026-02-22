defmodule Sayfa.ExcerptTest do
  use ExUnit.Case, async: true

  alias Sayfa.Excerpt

  describe "extract/2" do
    test "uses manual excerpt from meta when available" do
      content = %Sayfa.Content{
        title: "Test",
        body: "<p>This is the body content that should be ignored.</p>",
        meta: %{"excerpt" => "This is the manual excerpt."}
      }

      assert Excerpt.extract(content) == "This is the manual excerpt."
    end

    test "extracts first paragraph when no manual excerpt" do
      content = %Sayfa.Content{
        title: "Test",
        body: "<p>First paragraph here.</p><p>Second paragraph.</p>",
        meta: %{}
      }

      assert Excerpt.extract(content) == "First paragraph here."
    end

    test "strips HTML tags from first paragraph" do
      content = %Sayfa.Content{
        title: "Test",
        body: "<p>Text with <strong>bold</strong> and <em>italic</em> tags.</p>",
        meta: %{}
      }

      assert Excerpt.extract(content) == "Text with bold and italic tags."
    end

    test "falls back to body text when no paragraphs" do
      content = %Sayfa.Content{
        title: "Test",
        body: "Plain text without paragraph tags",
        meta: %{}
      }

      assert Excerpt.extract(content) == "Plain text without paragraph tags"
    end

    test "truncates long excerpts to default length" do
      long_text = String.duplicate("word ", 50)

      content = %Sayfa.Content{
        title: "Test",
        body: "<p>#{long_text}</p>",
        meta: %{}
      }

      result = Excerpt.extract(content)
      assert String.length(result) <= 163
      assert String.ends_with?(result, "...")
    end

    test "respects custom length option" do
      content = %Sayfa.Content{
        title: "Test",
        body: "<p>This is a medium length excerpt that will be truncated.</p>",
        meta: %{}
      }

      result = Excerpt.extract(content, length: 20)
      assert String.length(result) <= 23
      assert String.ends_with?(result, "...")
    end

    test "does not truncate short excerpts" do
      content = %Sayfa.Content{
        title: "Test",
        body: "<p>Short text.</p>",
        meta: %{}
      }

      assert Excerpt.extract(content) == "Short text."
    end

    test "handles empty body gracefully" do
      content = %Sayfa.Content{
        title: "Test",
        body: "",
        meta: %{}
      }

      assert Excerpt.extract(content) == ""
    end

    test "handles body with only whitespace" do
      content = %Sayfa.Content{
        title: "Test",
        body: "   \n  \t  ",
        meta: %{}
      }

      assert Excerpt.extract(content) == ""
    end

    test "handles complex HTML with nested tags" do
      content = %Sayfa.Content{
        title: "Test",
        body: "<p>Text with <a href=\"#\">link</a> and <code>code</code> inside.</p>",
        meta: %{}
      }

      assert Excerpt.extract(content) == "Text with link and code inside."
    end

    test "normalizes multiple spaces to single space" do
      content = %Sayfa.Content{
        title: "Test",
        body: "<p>Text   with    multiple     spaces.</p>",
        meta: %{}
      }

      assert Excerpt.extract(content) == "Text with multiple spaces."
    end
  end
end
