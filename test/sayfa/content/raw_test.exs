defmodule Sayfa.Content.RawTest do
  use ExUnit.Case, async: true

  alias Sayfa.Content.Raw

  describe "struct creation" do
    test "creates struct with required fields" do
      raw = %Raw{
        path: "content/posts/hello.md",
        front_matter: %{"title" => "Hello"},
        body_markdown: "# Hello"
      }

      assert raw.path == "content/posts/hello.md"
      assert raw.front_matter == %{"title" => "Hello"}
      assert raw.body_markdown == "# Hello"
      assert raw.filename == nil
    end

    test "creates struct with all fields" do
      raw = %Raw{
        path: "content/posts/2024-01-15-hello.md",
        front_matter: %{"title" => "Hello", "date" => ~D[2024-01-15]},
        body_markdown: "# Hello World",
        filename: "2024-01-15-hello.md"
      }

      assert raw.filename == "2024-01-15-hello.md"
    end

    test "raises when missing required fields" do
      assert_raise ArgumentError, fn ->
        struct!(Raw, %{path: "test.md"})
      end
    end
  end
end
