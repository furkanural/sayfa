# Image Optimization Guide

This guide explains how to optimize images for your Sayfa site.

## How This Integrates with Sayfa

Running the optimization script produces `.webp` and `.avif` variants of your
images on disk — but it does **not** automatically change your HTML output.
Markdown like `![alt](hero.jpg)` always renders to a bare `<img>` tag.

To make the browser actually load the modern variants, you need either:

- **Automatic approach** — Enable the built-in `Sayfa.Hooks.ResponsiveImages`
  hook (recommended, one line of config).
- **Manual approach** — Write `<picture>` elements by hand in your templates
  or content files.

---

## Prerequisites

Install one of these tools:

**vips** (recommended — fast, low memory):

```bash
# macOS
brew install vips

# Debian / Ubuntu
apt install libvips-tools
```

**ImageMagick** (fallback):

```bash
# macOS
brew install imagemagick

# Debian / Ubuntu
apt install imagemagick
```

## Running the Script

```bash
bash scripts/optimize_images.sh
```

By default the script processes all `.jpg`, `.jpeg`, and `.png` files in
`static/images/` and writes outputs alongside the originals.

Custom paths:

```bash
bash scripts/optimize_images.sh static/uploads static/uploads
```

## What the Script Does

For each source image the script produces:

| Output | Description |
|--------|-------------|
| `{name}_1200.jpg` | Resized JPEG, max 1200px wide |
| `{name}.webp` | WebP variant (smaller file size) |
| `{name}.avif` | AVIF variant (vips ≥ 8.11 only) |

---

## Automatic `<picture>` Wrapping (Recommended)

Sayfa ships a built-in hook — `Sayfa.Hooks.ResponsiveImages` — that
automatically rewrites every locally-sourced JPEG/PNG `<img>` tag to a
`<picture>` element after rendering:

```html
<!-- Markdown: ![Hero](/images/hero.jpg) renders to this before the hook -->
<img src="/images/hero.jpg" alt="Hero">

<!-- After the hook runs -->
<picture>
  <source srcset="/images/hero.avif" type="image/avif">
  <source srcset="/images/hero.webp" type="image/webp">
  <img src="/images/hero.jpg" alt="Hero">
</picture>
```

### Enabling the hook

Add one line to `config/config.exs`:

```elixir
config :sayfa, :hooks, [Sayfa.Hooks.ResponsiveImages]
```

That's it. Every page built by `mix sayfa.build` will have its `<img>` tags
upgraded automatically.

### Notes

- Only **local** paths (starting with `/`) are transformed. External URLs such
  as `https://cdn.example.com/img.jpg` are left untouched.
- Images already wrapped in `<picture>` are never double-wrapped.
- The `.webp` and `.avif` files **must exist on disk**. The hook rewrites HTML
  unconditionally; if a variant is missing the browser falls back to the
  original `<img src>`.
- Run `bash scripts/optimize_images.sh` before `mix sayfa.build` (or add it
  to your CI pipeline — see below) so the variants are always present.

---

## Manual `<picture>` Elements

For images in templates or when you need fine-grained control (e.g. explicit
`width`/`height` attributes to prevent layout shift), write `<picture>`
elements by hand:

```html
<picture>
  <source srcset="/images/hero.avif" type="image/avif">
  <source srcset="/images/hero.webp" type="image/webp">
  <img src="/images/hero_1200.jpg" alt="Hero image" width="1200" height="630">
</picture>
```

---

## Elixir-Native Processing (Optional)

For Elixir-native image processing, add the `image` package to your project:

```elixir
# mix.exs
{:image, "~> 0.56"}
```

Then call it from a hook or custom Mix task:

```elixir
Image.open!("static/images/hero.jpg")
|> Image.thumbnail!(1200)
|> Image.write!("static/images/hero.webp")
```

See https://hexdocs.pm/image for full documentation.

## Integrating with Your Build

Add the script to your CI pipeline or as a pre-build step:

```bash
# .github/workflows/deploy.yml
- name: Optimize images
  run: bash scripts/optimize_images.sh

- name: Build site
  run: mix sayfa.build
```
