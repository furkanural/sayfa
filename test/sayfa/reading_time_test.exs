defmodule Sayfa.ReadingTimeTest do
  use ExUnit.Case, async: true
  doctest Sayfa.ReadingTime

  alias Sayfa.ReadingTime

  describe "calculate/1" do
    test "returns 1 minute for short text" do
      assert ReadingTime.calculate("<p>Hello world</p>") == 1
    end

    test "returns 1 minute for empty string" do
      assert ReadingTime.calculate("") == 1
    end

    test "calculates correct minutes for longer text" do
      # 600 words at 200 WPM = 3 minutes
      words = String.duplicate("word ", 600)
      assert ReadingTime.calculate("<p>#{words}</p>") == 3
    end

    test "strips HTML tags before counting" do
      html = "<p><strong>Hello</strong> <em>world</em> <a href='#'>link</a></p>"
      assert ReadingTime.calculate(html) == 1
    end

    test "handles multiple paragraphs" do
      words = String.duplicate("word ", 400)
      html = "<p>#{words}</p><p>#{words}</p>"
      # 800 words / 200 = 4 minutes
      assert ReadingTime.calculate(html) == 4
    end
  end
end
