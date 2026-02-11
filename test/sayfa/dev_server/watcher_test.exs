defmodule Sayfa.DevServer.WatcherTest do
  use ExUnit.Case, async: true

  alias Sayfa.DevServer.Watcher

  describe "relevant_file?/1" do
    test "markdown files are relevant" do
      assert Watcher.relevant_file?("content/posts/hello.md")
    end

    test "EEx templates are relevant" do
      assert Watcher.relevant_file?("themes/default/layouts/base.html.eex")
    end

    test "HTML files are relevant" do
      assert Watcher.relevant_file?("themes/default/layouts/page.html")
    end

    test "CSS files are relevant" do
      assert Watcher.relevant_file?("themes/default/assets/style.css")
    end

    test "JS files are relevant" do
      assert Watcher.relevant_file?("themes/default/assets/app.js")
    end

    test "YAML files are relevant" do
      assert Watcher.relevant_file?("config/site.yaml")
      assert Watcher.relevant_file?("config/site.yml")
    end

    test "Elixir config files are relevant" do
      assert Watcher.relevant_file?("config/site.exs")
    end

    test "JSON files are relevant" do
      assert Watcher.relevant_file?("data/menu.json")
    end

    test "image files are not relevant" do
      refute Watcher.relevant_file?("content/images/photo.jpg")
      refute Watcher.relevant_file?("content/images/photo.png")
    end

    test "binary files are not relevant" do
      refute Watcher.relevant_file?("content/files/doc.pdf")
      refute Watcher.relevant_file?("output/something.beam")
    end

    test "files without extension are not relevant" do
      refute Watcher.relevant_file?("Makefile")
    end
  end
end
