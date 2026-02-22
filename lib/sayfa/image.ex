defmodule Sayfa.Image do
  @moduledoc """
  Image helper functions for templates.

  Provides responsive image markup generation. Note: This does NOT
  perform image optimization or resizing - it only generates the HTML
  markup for responsive images. Images must be prepared manually.

  ## Usage in templates

      <%= Sayfa.Image.responsive("/images/cover.jpg",
            alt: "Cover image",
            sizes: "100vw",
            widths: [400, 800, 1200]) %>

  ## Image preparation

  For the helper to work correctly, you must manually create resized
  versions of your images with the naming pattern:

      static/images/photo.jpg         # Original
      static/images/photo-600w.jpg    # Resized to 600px width
      static/images/photo-1200w.jpg   # Resized to 1200px width

  You can use ImageMagick or similar tools:

      convert static/images/photo.jpg -resize 600 static/images/photo-600w.jpg

  """

  @doc """
  Generates responsive image HTML with srcset.

  Expects images to exist at `/images/filename-{width}w.ext` pattern.

  ## Options

  - `:alt` - Alt text (required)
  - `:class` - CSS classes
  - `:loading` - "lazy" or "eager" (default: "lazy")
  - `:decoding` - "async" or "sync" (default: "async")
  - `:sizes` - Sizes attribute (default: "100vw")
  - `:widths` - List of widths for srcset (default: [400, 800, 1200])

  ## Examples

      iex> Sayfa.Image.responsive("/images/hero.jpg", alt: "Hero", widths: [600, 1200])
      "<img src=\\"/images/hero.jpg\\" srcset=\\"/images/hero-600w.jpg 600w, /images/hero-1200w.jpg 1200w\\" sizes=\\"100vw\\" alt=\\"Hero\\" loading=\\"lazy\\" decoding=\\"async\\">"

  """
  @spec responsive(String.t(), keyword()) :: String.t()
  def responsive(src, opts) do
    alt = Keyword.fetch!(opts, :alt)
    class = Keyword.get(opts, :class, "")
    loading = Keyword.get(opts, :loading, "lazy")
    decoding = Keyword.get(opts, :decoding, "async")
    sizes = Keyword.get(opts, :sizes, "100vw")
    widths = Keyword.get(opts, :widths, [400, 800, 1200])

    srcset = generate_srcset(src, widths)

    class_attr = if class == "", do: "", else: " class=\"#{escape_html(class)}\""

    "<img src=\"#{escape_html(src)}\" srcset=\"#{escape_html(srcset)}\" sizes=\"#{escape_html(sizes)}\" alt=\"#{escape_html(alt)}\" loading=\"#{escape_html(loading)}\" decoding=\"#{escape_html(decoding)}\"#{class_attr}>"
  end

  defp generate_srcset(src, widths) do
    ext = Path.extname(src)
    base = Path.rootname(src)

    Enum.map_join(widths, ", ", fn w -> "#{base}-#{w}w#{ext} #{w}w" end)
  end

  defp escape_html(text) when is_binary(text) do
    text
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
    |> String.replace("'", "&#39;")
  end

  defp escape_html(text), do: to_string(text)
end
