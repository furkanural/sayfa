defmodule Mix.Tasks.Sayfa.Gen.ContentTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Mix.Tasks.Sayfa.Gen.Content

  setup do
    # Create a temporary directory for test content
    tmp_dir = Path.join(System.tmp_dir!(), "sayfa_test_#{:rand.uniform(999_999)}")
    File.mkdir_p!(tmp_dir)

    # Store original content_types config
    original_config = Application.get_env(:sayfa, :content_types)

    on_exit(fn ->
      # Cleanup temp directory
      File.rm_rf!(tmp_dir)

      # Restore original config
      if original_config do
        Application.put_env(:sayfa, :content_types, original_config)
      else
        Application.delete_env(:sayfa, :content_types)
      end
    end)

    {:ok, tmp_dir: tmp_dir, original_config: original_config}
  end

  describe "slug generation" do
    test "uses custom slug when provided via --slug" do
      Application.delete_env(:sayfa, :content_types)

      output =
        capture_io(fn ->
          Content.run(["article", "My Title", "--slug", "custom-slug", "--date", "2024-01-15"])
        end)

      assert output =~ "custom-slug.md"
    end

    test "slugifies title when no --slug provided" do
      Application.delete_env(:sayfa, :content_types)

      output =
        capture_io(fn ->
          Content.run(["article", "Hello World Test", "--date", "2024-01-15"])
        end)

      assert output =~ "hello-world-test.md"
    end
  end

  describe "multilingual content generation" do
    test "generates multiple language versions with translations" do
      Application.delete_env(:sayfa, :content_types)

      output =
        capture_io(fn ->
          Content.run(["article", "Test Article", "--lang", "en,tr", "--date", "2024-01-15"])
        end)

      # Should create both language versions
      assert output =~ "content/articles/2024-01-15-test-article.md"
      assert output =~ "content/tr/articles/2024-01-15-test-article.md"
    end
  end

  describe "error handling" do
    test "exits with error for unknown content type" do
      Application.delete_env(:sayfa, :content_types)

      # Mix.shell().error goes to stderr, but we can verify by checking exit code
      # and that the listing is shown
      output =
        capture_io(fn ->
          assert catch_exit(Content.run(["unknown_type", "Test Title"])) == {:shutdown, 1}
        end)

      # The listing is shown after error (via IO.puts which goes to stdout)
      assert output =~ "Available content types:"
      assert output =~ "article"
    end

    test "shows usage error when missing arguments" do
      output =
        capture_io(fn ->
          assert catch_exit(Content.run([])) == {:shutdown, 1}
        end)

      # The listing is shown after error
      assert output =~ "Available content types:"
    end
  end

  describe "--list option" do
    test "lists available content types" do
      Application.delete_env(:sayfa, :content_types)

      output =
        capture_io(fn ->
          Content.run(["--list"])
        end)

      assert output =~ "Available content types:"
      assert output =~ "article"
      assert output =~ "note"
      assert output =~ "project"
      assert output =~ "talk"
      assert output =~ "page"
    end
  end
end
