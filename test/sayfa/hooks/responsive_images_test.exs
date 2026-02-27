defmodule Sayfa.Hooks.ResponsiveImagesTest do
  use ExUnit.Case, async: true

  alias Sayfa.Hooks.ResponsiveImages

  @content %Sayfa.Content{title: "Test", body: ""}

  describe "stage/0" do
    test "returns :after_render" do
      assert ResponsiveImages.stage() == :after_render
    end
  end

  describe "run/2" do
    test "returns {:ok, {content, html}} tuple" do
      html = ~s(<img src="/images/hero.jpg" alt="Hero">)
      assert {:ok, {@content, transformed}} = ResponsiveImages.run({@content, html}, %{})
      assert is_binary(transformed)
    end

    test "wraps local jpg in picture element" do
      html = ~s(<img src="/images/hero.jpg" alt="A">)
      {:ok, {_, result}} = ResponsiveImages.run({@content, html}, %{})

      assert result =~ ~s(<picture>)
      assert result =~ ~s(<source srcset="/images/hero.avif" type="image/avif">)
      assert result =~ ~s(<source srcset="/images/hero.webp" type="image/webp">)
      assert result =~ ~s(<img src="/images/hero.jpg")
      assert result =~ ~s(</picture>)
    end

    test "wraps local png in picture element" do
      html = ~s(<img src="/images/photo.png" alt="B">)
      {:ok, {_, result}} = ResponsiveImages.run({@content, html}, %{})

      assert result =~ ~s(<source srcset="/images/photo.avif" type="image/avif">)
      assert result =~ ~s(<source srcset="/images/photo.webp" type="image/webp">)
      assert result =~ ~s(<img src="/images/photo.png")
    end

    test "wraps .jpeg extension" do
      html = ~s(<img src="/foo.jpeg">)
      {:ok, {_, result}} = ResponsiveImages.run({@content, html}, %{})

      assert result =~ ~s(<source srcset="/foo.avif" type="image/avif">)
      assert result =~ ~s(<source srcset="/foo.webp" type="image/webp">)
    end

    test "preserves all attributes on the img tag" do
      html = ~s(<img src="/a.jpg" alt="x" class="wide" loading="lazy">)
      {:ok, {_, result}} = ResponsiveImages.run({@content, html}, %{})

      assert result =~ ~s(alt="x")
      assert result =~ ~s(class="wide")
      assert result =~ ~s(loading="lazy")
      assert result =~ ~s(<img src="/a.jpg")
    end

    test "leaves external URLs unchanged" do
      html = ~s(<img src="https://cdn.example.com/img.jpg">)
      {:ok, {_, result}} = ResponsiveImages.run({@content, html}, %{})

      refute result =~ "<picture>"
      assert result == html
    end

    test "does not double-wrap img already inside a picture element" do
      html = """
      <picture>
        <source srcset="/images/hero.avif" type="image/avif">
        <source srcset="/images/hero.webp" type="image/webp">
        <img src="/images/hero.jpg" alt="Hero">
      </picture>
      """

      {:ok, {_, result}} = ResponsiveImages.run({@content, html}, %{})

      # Should not gain a second <picture> wrapper
      picture_count = result |> String.split("<picture>") |> length() |> Kernel.-(1)
      assert picture_count == 1
    end

    test "leaves non-image src unchanged" do
      html = ~s(<img src="/icon.svg">)
      {:ok, {_, result}} = ResponsiveImages.run({@content, html}, %{})

      refute result =~ "<picture>"
      assert result == html
    end

    test "leaves webp src unchanged" do
      html = ~s(<img src="/hero.webp">)
      {:ok, {_, result}} = ResponsiveImages.run({@content, html}, %{})

      refute result =~ "<picture>"
      assert result == html
    end

    test "wraps multiple local images independently" do
      html =
        ~s(<img src="/images/a.jpg" alt="First">) <>
          " some text " <>
          ~s(<img src="/images/b.png" alt="Second">)

      {:ok, {_, result}} = ResponsiveImages.run({@content, html}, %{})

      picture_count = result |> String.split("<picture>") |> length() |> Kernel.-(1)
      assert picture_count == 2
      assert result =~ ~s(<source srcset="/images/a.avif")
      assert result =~ ~s(<source srcset="/images/b.avif")
    end
  end
end
