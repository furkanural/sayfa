defmodule Sayfa.ImageTest do
  use ExUnit.Case, async: true

  alias Sayfa.Image

  describe "responsive/2" do
    test "generates basic responsive image with default options" do
      result = Image.responsive("/images/photo.jpg", alt: "Test photo")

      assert result =~ "src=\"/images/photo.jpg\""
      assert result =~ "alt=\"Test photo\""
      assert result =~ "loading=\"lazy\""
      assert result =~ "decoding=\"async\""
    end

    test "generates srcset with default widths" do
      result = Image.responsive("/images/photo.jpg", alt: "Test")

      assert result =~
               "srcset=\"/images/photo-400w.jpg 400w, /images/photo-800w.jpg 800w, /images/photo-1200w.jpg 1200w\""
    end

    test "generates srcset with custom widths" do
      result = Image.responsive("/images/photo.jpg", alt: "Test", widths: [600, 1200])

      assert result =~ "srcset=\"/images/photo-600w.jpg 600w, /images/photo-1200w.jpg 1200w\""
    end

    test "includes custom sizes attribute" do
      result =
        Image.responsive("/images/photo.jpg",
          alt: "Test",
          sizes: "(max-width: 768px) 100vw, 50vw"
        )

      assert result =~ "sizes=\"(max-width: 768px) 100vw, 50vw\""
    end

    test "includes custom CSS classes" do
      result = Image.responsive("/images/photo.jpg", alt: "Test", class: "rounded-lg shadow-md")

      assert result =~ "class=\"rounded-lg shadow-md\""
    end

    test "omits class attribute when not provided" do
      result = Image.responsive("/images/photo.jpg", alt: "Test")

      refute result =~ "class="
    end

    test "supports eager loading" do
      result = Image.responsive("/images/photo.jpg", alt: "Test", loading: "eager")

      assert result =~ "loading=\"eager\""
    end

    test "supports sync decoding" do
      result = Image.responsive("/images/photo.jpg", alt: "Test", decoding: "sync")

      assert result =~ "decoding=\"sync\""
    end

    test "escapes HTML in alt text" do
      result = Image.responsive("/images/photo.jpg", alt: "Test <script>alert('xss')</script>")

      assert result =~ "alt=\"Test &lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;\""
      refute result =~ "<script>"
    end

    test "escapes HTML in src" do
      result = Image.responsive("/images/photo.jpg?param=<script>", alt: "Test")

      assert result =~ "src=\"/images/photo.jpg?param=&lt;script&gt;\""
    end

    test "escapes HTML in class" do
      result =
        Image.responsive("/images/photo.jpg", alt: "Test", class: "class\" onload=\"alert('xss')")

      assert result =~ "class=\"class&quot; onload=&quot;alert(&#39;xss&#39;)\""
      refute result =~ "onload=\"alert"
    end

    test "handles different file extensions" do
      result = Image.responsive("/images/photo.png", alt: "Test", widths: [600])

      assert result =~ "srcset=\"/images/photo-600w.png 600w\""
    end

    test "handles files with dots in name" do
      result = Image.responsive("/images/my.photo.jpg", alt: "Test", widths: [600])

      assert result =~ "srcset=\"/images/my.photo-600w.jpg 600w\""
    end

    test "handles nested directory paths" do
      result = Image.responsive("/images/blog/2024/photo.jpg", alt: "Test", widths: [600])

      assert result =~ "src=\"/images/blog/2024/photo.jpg\""
      assert result =~ "srcset=\"/images/blog/2024/photo-600w.jpg 600w"
    end

    test "raises when alt is missing" do
      assert_raise KeyError, fn ->
        Image.responsive("/images/photo.jpg", widths: [600])
      end
    end
  end
end
