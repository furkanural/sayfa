defmodule Sayfa.LlmsTxtTest do
  use ExUnit.Case, async: true
  doctest Sayfa.LlmsTxt

  alias Sayfa.Content
  alias Sayfa.LlmsTxt

  @config %{title: "My Blog", description: "Notes on Elixir", base_url: "https://example.com"}

  defp make_content(type, slug, opts \\ []) do
    meta =
      Map.merge(
        %{
          "content_type" => type,
          "url_prefix" => if(type == "pages", do: "", else: type),
          "lang_prefix" => ""
        },
        Keyword.get(opts, :meta, %{})
      )

    struct!(
      Content,
      [title: "Post #{slug}", body: "", slug: slug]
      |> Keyword.merge(Keyword.delete(opts, :meta))
      |> Keyword.put(:meta, meta)
    )
  end

  describe "generate/2" do
    test "includes site title and description" do
      text = LlmsTxt.generate([], @config)

      assert text =~ "# My Blog"
      assert text =~ "> Notes on Elixir"
    end

    test "omits blockquote when description is missing" do
      text = LlmsTxt.generate([], %{title: "My Blog"})

      assert text =~ "# My Blog"
      refute text =~ ">"
    end

    test "groups content by type with capitalized section headers" do
      contents = [make_content("articles", "a"), make_content("notes", "n")]
      text = LlmsTxt.generate(contents, @config)

      assert text =~ "## Articles"
      assert text =~ "## Notes"
    end

    test "links to absolute .md mirror URLs" do
      text = LlmsTxt.generate([make_content("articles", "hello")], @config)

      assert text =~ "- [Post hello](https://example.com/articles/hello.md)"
    end

    test "uses relative links when base_url is missing" do
      config = Map.delete(@config, :base_url)
      text = LlmsTxt.generate([make_content("articles", "hello")], config)

      assert text =~ "(/articles/hello.md)"
    end

    test "appends description after the link when present" do
      content = make_content("articles", "hello", meta: %{"description" => "First post"})
      text = LlmsTxt.generate([content], @config)

      assert text =~ "](https://example.com/articles/hello.md): First post"
    end

    test "sorts items by date descending within a section" do
      older = make_content("articles", "older", date: ~D[2024-01-01])
      newer = make_content("articles", "newer", date: ~D[2026-01-01])
      text = LlmsTxt.generate([older, newer], @config)

      assert text =~ ~r/newer\.md.*older\.md/s
    end

    test "orders sections with articles first and pages last" do
      contents = [make_content("pages", "about"), make_content("articles", "a")]
      text = LlmsTxt.generate(contents, @config)

      assert text =~ ~r/## Articles.*## Pages/s
    end

    test "skips content with the index slug" do
      text = LlmsTxt.generate([make_content("pages", "index")], @config)

      refute text =~ "index.md"
      refute text =~ "## Pages"
    end
  end
end
