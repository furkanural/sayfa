# Sayfa

[![Hex Version](https://img.shields.io/hexpm/v/sayfa.svg)](https://hex.pm/packages/sayfa)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Elixir](https://img.shields.io/badge/elixir-~%3E%201.18-purple.svg)](https://elixir-lang.org/)

A simple, extensible static site generator built in Elixir. **Sayfa** means "page" in Turkish.

[Turkce README / Turkish README](README.tr.md)

---

## Table of Contents

- [What is Sayfa?](#what-is-sayfa)
- [Features](#features)
- [Requirements](#requirements)
- [Quick Start](#quick-start)
- [Content Types](#content-types)
- [Front Matter](#front-matter)
- [Layouts & Templates](#layouts--templates)
- [Blocks](#blocks)
- [Themes](#themes)
- [Multilingual Support](#multilingual-support)
- [Feeds & SEO](#feeds--seo)
- [Configuration](#configuration)
- [CLI Commands](#cli-commands)
- [Project Structure](#project-structure)
- [Deployment](#deployment)
- [Extensibility](#extensibility)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [License](#license)

---

## What is Sayfa?

Sayfa follows a **two-layer architecture**:

1. **Sayfa** (this package) — A reusable Hex package with the core static site generation engine: markdown parsing, template rendering, feed generation, block system, and more.
2. **Your site** — A project that depends on Sayfa via `{:sayfa, "~> 0.1"}`. You bring your content, theme, and configuration; Sayfa handles the build.

```
┌──────────────────────────────────────────────────────┐
│                  YOUR WEBSITE                        │
│   content/     themes/     lib/blocks/    config/    │
└──────────────────────────┬───────────────────────────┘
                           │ {:sayfa, "~> 0.1"}
                           ▼
┌──────────────────────────────────────────────────────┐
│                  SAYFA (Hex Package)                 │
│  Builder, Content, Markdown, Feed, Sitemap, Blocks   │
└──────────────────────────────────────────────────────┘
```

### Design Philosophy

- **Simple** — Convention over configuration. Sensible defaults, minimal boilerplate.
- **Extensible** — Blocks, hooks, content types, and themes are all pluggable via behaviours.
- **Fast** — Markdown parsing powered by MDEx (Rust NIF). Incremental builds with caching.
- **No Node.js** — TailwindCSS is auto-downloaded via the `tailwind` hex package. Pure Elixir + Rust.

---

## Features

### Core
- Markdown with syntax highlighting (MDEx, Rust NIF)
- YAML front matter with typed fields + `meta` catch-all
- Two-struct content pipeline (`Raw` -> `Content`) for maximum flexibility

### Content Organization
- 5 built-in content types (posts, notes, projects, talks, pages)
- Categories and tags with auto-generated archive pages
- Pagination with configurable page size
- Collections API (filter, sort, group, recent)

### Templates & Theming
- Three-layer template composition (content -> layout -> base)
- 16 built-in blocks (hero, header, footer, social links, TOC, recent posts, tag cloud, category cloud, reading time, code copy, copy link, breadcrumb, recent content, search, language switcher, related posts) with 24 platform icons including GitHub, X/Twitter, Mastodon, LinkedIn, Bluesky, YouTube, Instagram, and more
- Theme inheritance (custom -> parent -> default)
- EEx templates with `@block` helper

### Internationalization
- Directory-based multilingual support
- Per-language URL prefixes (`/tr/posts/...`)
- 14 pre-built UI translations (en, tr, de, es, fr, it, pt, ja, ko, zh, ar, ru, nl, pl)
- Language switcher block with auto-detection of available translations
- RTL language support (Arabic, Hebrew, Farsi, Urdu)
- Auto-linked translations between content files
- Translation function `@t.("key")` in templates

### SEO & Feeds
- Atom feed generation
- Sitemap XML
- Pagefind static search integration
- SEO meta tags (Open Graph, description)

### Developer Experience
- `mix sayfa.new` project generator
- Dev server with file watching and hot reload
- Draft preview mode
- Build caching for incremental rebuilds
- Verbose logging with per-stage timing

---

## Requirements

| Requirement | Version | Notes |
|-------------|---------|-------|
| Elixir | ~> 1.18 | OTP 27+ |
| Rust | Latest stable | Required for MDEx NIF compilation |

Rust is a **hard requirement** — MDEx compiles a native extension for fast markdown parsing.

---

## Quick Start

```bash
# Install Sayfa's archive (for mix sayfa.new)
mix archive.install hex sayfa

# Create a new site
mix sayfa.new my_blog
cd my_blog
mix deps.get

# Build the site
mix sayfa.build

# Or start the dev server
mix sayfa.serve
```

Your site will be generated in the `output/` directory. The dev server runs at `http://localhost:4000` with hot reload.

---

## Content Types

Sayfa ships with 5 built-in content types. Each maps to a directory under `content/` and a URL prefix:

| Type | Directory | URL Pattern | Default Layout |
|------|-----------|-------------|----------------|
| Post | `content/posts/` | `/posts/{slug}/` | `post` |
| Note | `content/notes/` | `/notes/{slug}/` | `post` |
| Project | `content/projects/` | `/projects/{slug}/` | `page` |
| Talk | `content/talks/` | `/talks/{slug}/` | `page` |
| Page | `content/pages/` | `/{slug}/` | `page` |

No dates in URLs — keeps them clean and evergreen.

### Filename Convention

```
# Dated content (posts, notes)
2024-01-15-my-post-title.md  →  /posts/my-post-title/

# Undated content (projects, pages)
my-project.md                →  /projects/my-project/
about.md                     →  /about/
```

### Custom Content Types

Implement the `Sayfa.Behaviours.ContentType` behaviour:

```elixir
defmodule MyApp.ContentTypes.Recipe do
  @behaviour Sayfa.Behaviours.ContentType

  @impl true
  def name, do: :recipe

  @impl true
  def directory, do: "recipes"

  @impl true
  def url_prefix, do: "recipes"

  @impl true
  def default_layout, do: "page"

  @impl true
  def required_fields, do: [:title]
end
```

---

## Front Matter

Content files use YAML front matter delimited by `---`:

```yaml
---
title: "Building a Static Site Generator"   # Required
date: 2024-01-15                            # Required for posts/notes
slug: custom-slug                           # Optional (default: from filename)
lang: en                                    # Optional (default: site default)
description: "A brief description"          # Optional, used for SEO
categories: [elixir, tutorial]              # Optional
tags: [static-site, beginner]              # Optional
draft: false                                # Optional (default: false)
layout: custom_layout                       # Optional (default: content type's default)
---

Your markdown content here.
```

### Field Reference

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `title` | String | *required* | Page title |
| `date` | Date | `nil` | Publication date (YYYY-MM-DD) |
| `slug` | String | from filename | URL slug |
| `lang` | Atom | site default | Content language |
| `description` | String | `""` | SEO description |
| `categories` | List | `[]` | Category names |
| `tags` | List | `[]` | Tag names |
| `draft` | Boolean | `false` | Exclude from production builds |
| `layout` | String | type default | Layout template name |

Any unrecognized fields are stored in the `meta` map and accessible in templates via `@content.meta["field_name"]`.

---

## Layouts & Templates

Sayfa uses a **three-layer composition** model:

1. **Content body** — Markdown rendered to HTML
2. **Layout template** — Wraps the content, places blocks (e.g., `post.html.eex`)
3. **Base template** — HTML shell (`<html>`, `<head>`, etc.), inserts `@inner_content`

### Selecting a Layout

A page selects its layout via front matter:

```yaml
---
title: "Welcome"
layout: home
---
```

Resolution order:
1. `layout` field in front matter
2. Content type's `default_layout`
3. `page` (fallback)

### Default Layouts

| Layout | Used For | Typical Blocks |
|--------|----------|----------------|
| `home.html.eex` | Homepage | hero, recent_posts, tag_cloud |
| `post.html.eex` | Single post/note | reading_time, toc, social_links |
| `page.html.eex` | Static pages | content only |
| `list.html.eex` | Content listings | pagination |
| `base.html.eex` | HTML wrapper | header, footer |

### Template Variables

All templates receive these assigns:

| Variable | Type | Description |
|----------|------|-------------|
| `@content` | `Sayfa.Content.t()` | Current content (nil on list pages) |
| `@contents` | `[Sayfa.Content.t()]` | All site contents |
| `@site` | `map()` | Resolved site configuration |
| `@block` | `function` | Block rendering helper |
| `@t` | `function` | Translation function (`@t.("key")`) |
| `@lang` | `atom()` | Current content language |
| `@dir` | `String.t()` | Text direction (`"ltr"` or `"rtl"`) |
| `@inner_content` | `String.t()` | Rendered inner HTML (base layout only) |

---

## Blocks

Blocks are reusable EEx components invoked via the `@block` helper:

```eex
<%= @block.(:hero, title: "Welcome", subtitle: "My Elixir Blog") %>
<%= @block.(:recent_posts, limit: 5) %>
<%= @block.(:tag_cloud) %>
```

### Built-in Blocks

| Block | Atom | Description |
|-------|------|-------------|
| Hero | `:hero` | Hero section with title and subtitle |
| Header | `:header` | Site header with navigation |
| Footer | `:footer` | Site footer |
| Social Links | `:social_links` | Social media link icons |
| Table of Contents | `:toc` | Auto-generated TOC from headings |
| Recent Posts | `:recent_posts` | List of recent posts |
| Tag Cloud | `:tag_cloud` | Tag cloud with counts |
| Category Cloud | `:category_cloud` | Category cloud with counts |
| Reading Time | `:reading_time` | Estimated reading time |
| Code Copy | `:code_copy` | Copy button for code blocks |
| Copy Link | `:copy_link` | Copy page URL to clipboard |
| Breadcrumb | `:breadcrumb` | Breadcrumb navigation |
| Recent Content | `:recent_content` | Recent items from any content type |
| Language Switcher | `:language_switcher` | Switch between content translations |
| Related Posts | `:related_posts` | Posts related by tags/categories |

### Custom Blocks

Implement the `Sayfa.Behaviours.Block` behaviour:

```elixir
defmodule MyApp.Blocks.Banner do
  @behaviour Sayfa.Behaviours.Block

  @impl true
  def name, do: :banner

  @impl true
  def render(assigns) do
    text = Map.get(assigns, :text, "Welcome!")
    ~s(<div class="banner">#{text}</div>)
  end
end
```

Register custom blocks in your site config:

```elixir
config :sayfa, :site,
  blocks: [
    Sayfa.Blocks.Hero,
    MyApp.Blocks.Banner
  ]
```

Then use it in templates:

```eex
<%= @block.(:banner, text: "Hello from my custom block!") %>
```

---

## Themes

### Default Theme

Sayfa ships with a minimal, documentation-style default theme. It includes all 5 layouts and basic CSS.

### Custom Themes

Create a theme directory in your project:

```
themes/
  my_theme/
    layouts/
      post.html.eex    # Override specific layouts
    assets/
      css/
        custom.css
```

Set it in config:

```elixir
config :sayfa, :site,
  theme: "my_theme"
```

### Theme Inheritance

Custom themes inherit from a parent. Any layout not overridden falls back to the parent theme:

```elixir
config :sayfa, :site,
  theme: "my_theme",
  theme_parent: "default"
```

---

## Multilingual Support

Sayfa uses a directory-based approach for multilingual content:

```
content/
  posts/
    hello-world.md          # English (default)
  tr/
    posts/
      merhaba-dunya.md      # Turkish
```

### Configuration

```elixir
config :sayfa, :site,
  default_lang: :en,
  languages: [
    en: [name: "English"],
    tr: [name: "Türkçe"]
  ]
```

### URL Patterns

```
English (default):  /posts/hello-world/
Turkish:            /tr/posts/merhaba-dunya/
```

### Linking Translations

Use the `translations` front matter key to link content across languages. The builder also auto-links translations by matching slugs across language directories.

```yaml
---
title: "Hello World"
lang: en
translations:
  tr: merhaba-dunya
---
```

Generate pre-linked multilingual content in one command:

```bash
mix sayfa.gen.content post "Hello World" --lang=en,tr
```

### Translation Function

Templates receive a `@t` function for translating UI strings:

```eex
<%= @t.("recent_posts") %>   <%# "Recent Posts" in English, "Son Yazılar" in Turkish %>
<%= @t.("min_read") %>       <%# "min read" / "dk okuma" %>
```

Sayfa ships with 14 built-in translation files covering common UI strings:

`en`, `tr`, `de`, `es`, `fr`, `it`, `pt`, `ja`, `ko`, `zh`, `ar`, `ru`, `nl`, `pl`

Translation lookup chain:
1. Per-language overrides in config (`languages: [tr: [translations: %{"key" => "value"}]]`)
2. YAML file for the content language (`priv/translations/{lang}.yml`)
3. YAML file for the default language (fallback)
4. The key itself

### Per-Language Config Overrides

Override any site config per language:

```elixir
config :sayfa, :site,
  title: "My Blog",
  default_lang: :en,
  languages: [
    en: [name: "English"],
    tr: [name: "Türkçe", title: "Blogum", description: "Kişisel blogum"]
  ]
```

### RTL Support

Sayfa automatically sets `dir="rtl"` on the `<html>` tag for right-to-left languages: Arabic (`ar`), Hebrew (`he`), Farsi (`fa`), and Urdu (`ur`).

---

## Feeds & SEO

### Atom Feeds

Sayfa generates Atom XML feeds automatically:

```
/feed.xml              # All content
/feed/posts.xml        # Posts only
/feed/notes.xml        # Notes only
```

### Sitemap

A `sitemap.xml` is generated at the root of the output directory containing all published pages.

### SEO Meta Tags

Templates automatically include Open Graph and description meta tags based on front matter fields.

---

## Configuration

Site configuration lives in `config/config.exs`:

```elixir
import Config

config :sayfa, :site,
  # Basic
  title: "My Site",
  description: "A site built with Sayfa",
  author: "Your Name",
  base_url: "https://example.com",

  # Content
  content_dir: "content",
  output_dir: "output",
  posts_per_page: 10,
  drafts: false,

  # Language
  default_lang: :en,
  languages: [en: [name: "English"]],

  # Theme
  theme: "default",
  theme_parent: "default",

  # Dev server
  port: 4000,
  verbose: false
```

### Configuration Reference

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `title` | String | `"My Site"` | Site title |
| `description` | String | `""` | Site description |
| `author` | String | `nil` | Site author |
| `base_url` | String | `"http://localhost:4000"` | Production URL |
| `content_dir` | String | `"content"` | Content source directory |
| `output_dir` | String | `"output"` | Build output directory |
| `posts_per_page` | Integer | `10` | Pagination size |
| `drafts` | Boolean | `false` | Include drafts in build |
| `default_lang` | Atom | `:en` | Default content language |
| `languages` | Keyword | `[en: [name: "English"]]` | Available languages |
| `theme` | String | `"default"` | Active theme name |
| `theme_parent` | String | `"default"` | Parent theme for inheritance |
| `port` | Integer | `4000` | Dev server port |
| `verbose` | Boolean | `false` | Verbose build logging |

---

## CLI Commands

### `mix sayfa.new`

Generate a new Sayfa site:

```bash
mix sayfa.new my_blog
mix sayfa.new my_blog --theme minimal --lang en,tr
```

### `mix sayfa.build`

Build the site:

```bash
mix sayfa.build
mix sayfa.build --drafts              # Include draft content
mix sayfa.build --verbose             # Detailed logging
mix sayfa.build --output _site        # Custom output directory
mix sayfa.build --source ./my_site    # Custom source directory
```

### `mix sayfa.gen.content`

Generate a new content file:

```bash
mix sayfa.gen.content post "My First Post"
mix sayfa.gen.content note "Quick Tip" --tags=elixir,tips
mix sayfa.gen.content post "Hello World" --lang=en,tr    # Multilingual
mix sayfa.gen.content --list                              # List content types
```

Options: `--date`, `--tags`, `--categories`, `--draft`, `--lang`, `--slug`.

### `mix sayfa.serve`

Start the development server:

```bash
mix sayfa.serve
mix sayfa.serve --port 3000           # Custom port
mix sayfa.serve --drafts              # Preview drafts
```

The dev server watches for file changes and rebuilds automatically.

---

## Project Structure

A generated Sayfa site looks like this:

```
my_site/
├── config/
│   ├── config.exs
│   └── site.exs                # Site configuration
│
├── content/
│   ├── posts/                  # Blog posts
│   │   └── 2024-01-15-hello-world.md
│   ├── notes/                  # Quick notes
│   ├── projects/               # Portfolio projects
│   ├── talks/                  # Talks/presentations
│   ├── pages/                  # Static pages
│   │   └── about.md
│   └── tr/                     # Turkish translations
│       └── posts/
│
├── themes/
│   └── my_theme/               # Custom theme (optional)
│       └── layouts/
│
├── static/                     # Copied as-is to output
│   ├── images/
│   └── favicon.ico
│
├── lib/                        # Custom blocks, hooks, content types
│
├── output/                     # Generated site (git-ignored)
│
└── mix.exs
```

---

## Deployment

`mix sayfa.new` generates a **Dockerfile** and a **GitHub Actions workflow** so you can deploy immediately.

### GitHub Pages

Your generated project includes `.github/workflows/deploy.yml`. Enable GitHub Pages in your repo settings (set Source to **GitHub Actions**), and every push to `main` will build and deploy your site automatically.

### Docker / Coolify

A multi-stage `Dockerfile` is included — it builds your site with Elixir + Rust, then serves it with nginx:

```bash
docker build -t my-site .
docker run -p 8080:80 my-site
```

For [Coolify](https://coolify.io/), select the **Dockerfile** build pack.

### VPS (rsync)

Build locally and sync to your server:

```bash
mix sayfa.build
rsync -avz --delete output/ user@server:/var/www/my-site/
```

---

## Extensibility

Sayfa is designed to be extended via three behaviours:

### Blocks

Reusable template components. See the [Blocks](#blocks) section.

### Hooks

Inject custom logic into the build pipeline at 4 stages:

```elixir
defmodule MyApp.Hooks.InjectAnalytics do
  @behaviour Sayfa.Behaviours.Hook

  @impl true
  def stage, do: :after_render

  @impl true
  def run({content, html}, _opts) do
    {:ok, {content, html <> "<script>/* analytics */</script>"}}
  end
end
```

Register hooks in config:

```elixir
config :sayfa, :hooks, [MyApp.Hooks.InjectAnalytics]
```

**Hook stages:**

| Stage | Input | Description |
|-------|-------|-------------|
| `:before_parse` | `Content.Raw` | Before markdown rendering |
| `:after_parse` | `Content` | After parsing, before template |
| `:before_render` | `Content` | Before template rendering |
| `:after_render` | `{Content, html}` | After template rendering |

### Content Types

Define how content is organized. See [Custom Content Types](#custom-content-types).

---

## Roadmap

Future plans for Sayfa:

- Search functionality (client-side search with indexing)
- Image optimization (automatic resizing, WebP conversion)
- Dark mode toggle in default theme
- Plugin system for third-party extensions
- Asset fingerprinting

---

## Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

```bash
git clone https://github.com/furkanural/sayfa.git
cd sayfa
mix deps.get
mix test
```

---

## License

MIT License. See [LICENSE](LICENSE) for details.
