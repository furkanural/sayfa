defmodule Sayfa.Blocks.MarkdownLinkTest do
  use ExUnit.Case, async: true

  alias Sayfa.Blocks.MarkdownLink
  alias Sayfa.Content

  defp make_content(opts \\ []) do
    struct!(
      Content,
      [
        title: "Hello",
        body: "",
        slug: "hello",
        meta: %{"url_prefix" => "articles", "lang_prefix" => ""}
      ]
      |> Keyword.merge(opts)
    )
  end

  describe "render/1" do
    test "renders view link and copy button for mirrored content" do
      html = MarkdownLink.render(%{site: %{}, content: make_content(), lang: :en})

      assert html =~ ~s(href="/articles/hello.md")
      assert html =~ "View Markdown"
      assert html =~ ~s(data-action="copy-markdown")
      assert html =~ ~s(data-url="/articles/hello.md")
      assert html =~ "Copy Markdown"
      assert html =~ ~s(data-copied-text="Copied!")
    end

    test "renders nothing without content" do
      assert "" == MarkdownLink.render(%{site: %{}, content: nil, lang: :en})
    end

    test "renders nothing for the index slug" do
      content = make_content(slug: "index", meta: %{"url_prefix" => "", "lang_prefix" => ""})

      assert "" == MarkdownLink.render(%{site: %{}, content: content, lang: :en})
    end

    test "renders nothing when mirrors are disabled" do
      site = %{markdown_mirrors: false}

      assert "" == MarkdownLink.render(%{site: site, content: make_content(), lang: :en})
    end

    test "uses the translation function from assigns" do
      t = fn
        "view_markdown" -> "Markdown'ı görüntüle"
        "copy_markdown" -> "Markdown'ı kopyala"
        "copied" -> "Kopyalandı!"
        key -> key
      end

      html = MarkdownLink.render(%{site: %{}, content: make_content(), lang: :tr, t: t})

      assert html =~ "Markdown'ı görüntüle"
      assert html =~ "Markdown'ı kopyala"
    end
  end
end
