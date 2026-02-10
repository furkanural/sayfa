defmodule Sayfa.ContentTypeTest do
  use ExUnit.Case, async: true

  alias Sayfa.ContentType

  doctest Sayfa.ContentType

  describe "default_types/0" do
    test "returns 5 built-in types" do
      assert length(ContentType.default_types()) == 5
    end

    test "all types implement the content_type behaviour" do
      for mod <- ContentType.default_types() do
        assert is_atom(mod.name())
        assert is_binary(mod.directory())
        assert is_binary(mod.url_prefix())
        assert is_binary(mod.default_layout())
        assert is_list(mod.required_fields())
      end
    end
  end

  describe "all/0" do
    test "returns default types when no app config" do
      assert ContentType.all() == ContentType.default_types()
    end
  end

  describe "find_by_directory/1" do
    test "finds post type" do
      assert ContentType.find_by_directory("posts") == Sayfa.ContentTypes.Post
    end

    test "finds note type" do
      assert ContentType.find_by_directory("notes") == Sayfa.ContentTypes.Note
    end

    test "finds project type" do
      assert ContentType.find_by_directory("projects") == Sayfa.ContentTypes.Project
    end

    test "finds talk type" do
      assert ContentType.find_by_directory("talks") == Sayfa.ContentTypes.Talk
    end

    test "finds page type" do
      assert ContentType.find_by_directory("pages") == Sayfa.ContentTypes.Page
    end

    test "returns nil for unknown directory" do
      assert ContentType.find_by_directory("unknown") == nil
    end
  end

  describe "find_by_name/1" do
    test "finds post type" do
      assert ContentType.find_by_name(:post) == Sayfa.ContentTypes.Post
    end

    test "finds page type" do
      assert ContentType.find_by_name(:page) == Sayfa.ContentTypes.Page
    end

    test "returns nil for unknown name" do
      assert ContentType.find_by_name(:unknown) == nil
    end
  end

  describe "built-in type metadata" do
    test "post type" do
      mod = Sayfa.ContentTypes.Post
      assert mod.name() == :post
      assert mod.directory() == "posts"
      assert mod.url_prefix() == "posts"
      assert mod.default_layout() == "post"
      assert mod.required_fields() == [:title, :date]
    end

    test "note type" do
      mod = Sayfa.ContentTypes.Note
      assert mod.name() == :note
      assert mod.directory() == "notes"
      assert mod.url_prefix() == "notes"
      assert mod.default_layout() == "post"
      assert mod.required_fields() == [:title, :date]
    end

    test "project type" do
      mod = Sayfa.ContentTypes.Project
      assert mod.name() == :project
      assert mod.directory() == "projects"
      assert mod.url_prefix() == "projects"
      assert mod.default_layout() == "page"
      assert mod.required_fields() == [:title]
    end

    test "talk type" do
      mod = Sayfa.ContentTypes.Talk
      assert mod.name() == :talk
      assert mod.directory() == "talks"
      assert mod.url_prefix() == "talks"
      assert mod.default_layout() == "page"
      assert mod.required_fields() == [:title]
    end

    test "page type has empty url_prefix" do
      mod = Sayfa.ContentTypes.Page
      assert mod.name() == :page
      assert mod.directory() == "pages"
      assert mod.url_prefix() == ""
      assert mod.default_layout() == "page"
      assert mod.required_fields() == [:title]
    end
  end
end
