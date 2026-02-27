defmodule Sayfa.ValidatorTest do
  use ExUnit.Case, async: true

  alias Sayfa.Validator

  defp make_content(attrs) do
    defaults = %Sayfa.Content{title: "T", body: "", meta: %{}}
    Map.merge(defaults, Map.new(attrs))
  end

  describe "validate_all/1" do
    test "returns the contents list unchanged" do
      content = make_content(meta: %{"content_type" => "pages"})
      result = Validator.validate_all([content])
      assert result == [content]
    end

    test "validates all items in the list" do
      contents = [
        make_content(meta: %{"content_type" => "pages"}),
        make_content(meta: %{"content_type" => "posts"}, date: ~D[2024-01-01])
      ]

      result = Validator.validate_all(contents)
      assert length(result) == 2
    end
  end

  describe "validate_one/1" do
    test "returns :ok for pages without date" do
      content = make_content(meta: %{"content_type" => "pages"})
      assert :ok = Validator.validate_one(content)
    end

    test "returns :ok for posts with date" do
      content = make_content(date: ~D[2024-01-15], meta: %{"content_type" => "posts"})
      assert :ok = Validator.validate_one(content)
    end

    test "returns :ok for notes with date" do
      content = make_content(date: ~D[2024-01-15], meta: %{"content_type" => "notes"})
      assert :ok = Validator.validate_one(content)
    end

    test "returns :ok for posts without date (warning is logged but :ok returned)" do
      content = make_content(meta: %{"content_type" => "posts"})
      # validate_one always returns :ok; warning is a side effect
      assert :ok = Validator.validate_one(content)
    end

    test "returns :ok for notes without date (warning logged)" do
      content = make_content(meta: %{"content_type" => "notes"})
      assert :ok = Validator.validate_one(content)
    end

    test "returns :ok for unknown content type" do
      content = make_content(meta: %{"content_type" => "custom_type"})
      assert :ok = Validator.validate_one(content)
    end
  end
end
