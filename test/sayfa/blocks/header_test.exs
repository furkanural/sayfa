defmodule Sayfa.Blocks.HeaderTest do
  use ExUnit.Case, async: true

  alias Sayfa.Blocks.Header

  @base_site %{
    title: "My Site",
    default_lang: :en,
    languages: [en: [name: "English"]]
  }

  describe "render/1 — brand (logo vs title)" do
    test "renders site title as text when no logo configured" do
      assigns = %{site: @base_site, nav: [], lang: :en}
      html = Header.render(assigns)

      assert html =~ "My Site"
      refute html =~ "<img"
    end

    test "renders img tag when logo is configured" do
      site = Map.put(@base_site, :logo, "/images/logo.svg")
      assigns = %{site: site, nav: [], lang: :en}
      html = Header.render(assigns)

      assert html =~ ~s(<img src="/images/logo.svg")
      refute html =~ ~r/>My Site</
    end

    test "uses site title as alt text on logo img" do
      site = Map.put(@base_site, :logo, "/images/logo.svg")
      assigns = %{site: site, nav: [], lang: :en}
      html = Header.render(assigns)

      assert html =~ ~s(alt="My Site")
    end

    test "single logo img has no dark mode classes" do
      site = Map.put(@base_site, :logo, "/images/logo.svg")
      assigns = %{site: site, nav: [], lang: :en}
      html = Header.render(assigns)

      assert html =~ ~s(class="max-h-8 w-auto")
      refute html =~ "dark:hidden"
      refute html =~ "hidden dark:block"
    end

    test "renders dark logo pair when logo_dark is also configured" do
      site =
        @base_site
        |> Map.put(:logo, "/images/logo.svg")
        |> Map.put(:logo_dark, "/images/logo-dark.svg")

      assigns = %{site: site, nav: [], lang: :en}
      html = Header.render(assigns)

      assert html =~ ~s(src="/images/logo.svg")
      assert html =~ ~s(src="/images/logo-dark.svg")
      assert html =~ "dark:hidden"
      assert html =~ "hidden dark:block"
    end

    test "falls back to text when logo is nil" do
      site = Map.put(@base_site, :logo, nil)
      assigns = %{site: site, nav: [], lang: :en}
      html = Header.render(assigns)

      assert html =~ "My Site"
      refute html =~ "<img"
    end

    test "logo anchor uses opacity hover class instead of text color class" do
      site = Map.put(@base_site, :logo, "/images/logo.svg")
      assigns = %{site: site, nav: [], lang: :en}
      html = Header.render(assigns)

      assert html =~ "hover:opacity-80"
      refute html =~ "font-bold"
    end

    test "text title anchor uses font-bold class" do
      assigns = %{site: @base_site, nav: [], lang: :en}
      html = Header.render(assigns)

      assert html =~ "font-bold"
    end
  end
end
