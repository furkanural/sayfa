# Sayfa - Project Specification & Implementation Plan

**Sayfa** (Turkish for "page") is an open-source static site generator built in Elixir. It follows a two-layer architecture where Sayfa is a reusable Hex package, and users create their own sites by depending on it.

### Goals
- Build a simple, extensible SSG tool in Elixir
- Learn Elixir while shipping a usable product
- Allow others to use Sayfa for their own sites
- Support blocks (reusable components) and custom themes
- Meet minimum CMS requirements (RSS, sitemap, categories, search)

### Key Design Decisions
- MDEx only for markdown — Rust is a hard requirement, no Earmark fallback
- Separate `Sayfa.Content.Raw` struct for intermediate parsing (before markdown rendering)
- `meta` catch-all map in Content struct for custom front matter fields
- **Blocks replace widgets** — composable EEx components invoked via `@block.(:name, opts)` in templates
- **Three-layer layout composition** — content body → layout template → base template
- Any page can select its layout via front matter (`layout: home`, `layout: about`, etc.)

---

## Architecture

### Two-Layer Design

```
┌─────────────────────────────────────────────────────────────┐
│                    USER'S WEBSITE                            │
│  (content, custom theme, custom blocks, site config)        │
│                                                              │
│   content/        themes/         lib/blocks/    config/     │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ depends on {:sayfa, "~> x.x"}
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    SAYFA (Hex Package)                       │
│  (core engine, behaviours, default blocks, CLI tasks)       │
│                                                              │
│   Builder, Content, Markdown, Feed, Sitemap, I18n, Blocks   │
└─────────────────────────────────────────────────────────────┘
```

### Block System

Blocks are reusable EEx components invoked via a helper function injected into template assigns.

**How it works:**
1. Blocks implement `Sayfa.Behaviours.Block` with `name/0` and `render/1` callbacks
2. `Sayfa.BlockRegistry` maps atom names to block modules
3. A `@block` function is injected into every template's assigns, closing over the registry and site context
4. Templates call: `<%= @block.(:hero, title: "Welcome", subtitle: "My blog") %>`
5. The function looks up the module, merges site context with caller opts, calls `render/1`, returns HTML

```elixir
# In a template:
<%= @block.(:hero, title: "Welcome") %>
<%= @block.(:recent_posts, limit: 5) %>

# Block implementation:
defmodule Sayfa.Blocks.Hero do
  @behaviour Sayfa.Behaviours.Block
  def name, do: :hero
  def render(assigns) do
    # Return HTML string
  end
end
```

### Layout Composition (Three Layers)

1. **Content body** — markdown rendered to HTML
2. **Layout template** — wraps content, places blocks (e.g., `home.html.eex`, `post.html.eex`)
3. **Base template** — HTML shell (`<html>`, `<head>`, etc.), inserts `@inner_content`

A page selects its layout via front matter:
```yaml
---
title: "Welcome"
layout: home
---
```

Each layout uses different block combinations:
- `home.html.eex` — hero + recent_posts + tag_cloud
- `post.html.eex` — reading_time + toc + content + social_links
- `about.html.eex` — content only (minimal)
- `list.html.eex` — pagination + post cards
- `page.html.eex` — generic page wrapper

Users can create custom layouts in their theme directory.

### Content Pipeline

```
1. Load Configuration
       │
       ▼
2. Discover Content Files
       │
       ▼
3. Parse Front Matter + Markdown  ←── [Hook: before_parse, after_parse]
       │
       ▼
4. Build Collections (posts, tags, categories)
       │
       ▼
5. Render Templates  ←── [Hook: before_render, after_render]
       │
       ▼
6. Generate RSS/Sitemap
       │
       ▼
7. Copy Static Assets
       │
       ▼
8. Write Output Files  ←── [Hook: before_write, after_write]
       │
       ▼
9. Run Pagefind (search index)
       │
       ▼
10. Done!
```

### Two-Struct Design (Raw → Content)

1. **`Sayfa.Content.Raw`** — Intermediate representation after file parsing
   - Contains: path, front_matter (map), body_markdown (string), filename
   - Used for: Hooks that need raw markdown, caching, lazy rendering

2. **`Sayfa.Content`** — Final content ready for templates
   - Contains: title, body (HTML), date, slug, tags, categories, meta
   - Used for: Template rendering, collections, queries

---

## Requirements & Tech Stack

| Requirement | Version | Notes |
|-------------|---------|-------|
| Elixir | ~> 1.18 | Latest stable |
| OTP | 27+ | Required by Elixir 1.18 |
| Rust | Latest stable | Required for MDEx NIF compilation |

| Purpose | Library/Tool | Notes |
|---------|--------------|-------|
| Language | Elixir | Primary goal is learning Elixir |
| Markdown | MDEx | Rust NIF, fast, built-in syntax highlighting. **No fallback**. |
| Front matter | YamlElixir | Parse YAML metadata from markdown files |
| Templating | EEx | Built-in Elixir, no extra dependencies |
| CSS | TailwindCSS standalone CLI | No Node.js dependency |
| Search | Pagefind | Rust-based, runs post-build, generates static search index |
| File watching | FileSystem | For hot-reload dev server (Phase 6) |
| Image processing | Image | libvips-based optimization (Phase 4) |

### Dependencies by Phase

```elixir
# Phase 1 (minimal)
{:mdex, "~> 0.2"},
{:yaml_elixir, "~> 2.9"},

# Phase 3+
{:slugify, "~> 1.3"},
{:timex, "~> 3.7"},
{:xml_builder, "~> 2.2"},

# Dev dependencies (all phases)
{:ex_doc, "~> 0.34", only: :dev, runtime: false},
{:credo, "~> 1.7", only: [:dev, :test], runtime: false},

# Phase 6
{:file_system, "~> 1.0"},
{:plug_cowboy, "~> 2.6"},

# Optional
{:image, "~> 0.37"},
```

---

## Project Structure

### Sayfa Package

```
sayfa/
├── lib/
│   ├── sayfa.ex                      # Main public API
│   ├── sayfa/
│   │   ├── builder.ex                # Core build pipeline
│   │   ├── content.ex                # Content loading, parsing, collections
│   │   ├── content/
│   │   │   └── raw.ex                # Raw parsed content struct (before rendering)
│   │   ├── markdown.ex               # MDEx wrapper with syntax highlighting
│   │   ├── template.ex               # EEx template rendering
│   │   ├── config.ex                 # Site configuration handling
│   │   ├── theme.ex                  # Theme loading and inheritance
│   │   ├── feed.ex                   # RSS/Atom feed generation
│   │   ├── sitemap.ex                # Sitemap XML generation
│   │   ├── i18n.ex                   # Multilingual support
│   │   ├── pagination.ex             # List pagination
│   │   ├── reading_time.ex           # Reading time calculation
│   │   ├── toc.ex                    # Table of contents extraction
│   │   │
│   │   ├── behaviours/               # Extension contracts
│   │   │   ├── block.ex              # Block behaviour
│   │   │   ├── hook.ex               # Build hook behaviour
│   │   │   └── content_type.ex       # Custom content type behaviour
│   │   │
│   │   ├── block_registry.ex         # Block name → module lookup
│   │   │
│   │   ├── blocks/                   # Built-in blocks (reusable components)
│   │   │   ├── hero.ex               # Hero section
│   │   │   ├── header.ex             # Site header/navigation
│   │   │   ├── footer.ex             # Site footer
│   │   │   ├── social_links.ex       # Social media links
│   │   │   ├── toc.ex                # Table of contents
│   │   │   ├── recent_posts.ex       # Recent posts list
│   │   │   ├── tag_cloud.ex          # Tag cloud
│   │   │   ├── reading_time.ex       # Reading time display
│   │   │   └── code_copy.ex          # Copy button for code blocks
│   │   │
│   │   └── content_types/            # Built-in content types
│   │       ├── post.ex               # Blog posts
│   │       ├── note.ex               # Quick notes/TIL
│   │       ├── project.ex            # Portfolio projects
│   │       ├── talk.ex               # Talks/presentations
│   │       └── page.ex               # Static pages
│   │
│   └── mix/
│       └── tasks/
│           ├── sayfa.new.ex          # mix sayfa.new my_site
│           ├── sayfa.build.ex        # mix sayfa.build
│           └── sayfa.serve.ex        # mix sayfa.serve (dev server)
│
├── priv/
│   ├── templates/
│   │   └── new_site/                 # Template for mix sayfa.new
│   │       ├── config/
│   │       ├── content/
│   │       ├── themes/
│   │       └── mix.exs.eex
│   │
│   └── default_theme/                # Default theme (minimal, docs-style)
│       ├── layouts/
│       │   ├── base.html.eex         # Base HTML structure
│       │   ├── home.html.eex         # Homepage layout
│       │   ├── post.html.eex         # Single post layout
│       │   ├── list.html.eex         # Post listing layout
│       │   └── page.html.eex         # Static page layout
│       └── assets/
│           └── css/
│               └── theme.css         # TailwindCSS styles
│
├── test/
├── mix.exs
└── README.md
```

### User's Website (Example)

```
my_website/
├── config/
│   ├── config.exs                    # Elixir config
│   └── site.exs                      # Site-specific configuration
│
├── content/
│   ├── posts/                        # Blog posts (English default)
│   │   ├── 2024-01-15-hello-world.md
│   │   └── 2024-01-20-elixir-tips.md
│   ├── notes/                        # Quick notes
│   │   └── til-pattern-matching.md
│   ├── projects/                     # Portfolio projects
│   │   └── sayfa.md
│   ├── talks/                        # Talks/presentations
│   │   └── elixir-conf-2024.md
│   ├── pages/                        # Static pages
│   │   ├── about.md
│   │   └── uses.md
│   └── tr/                           # Turkish content
│       └── posts/
│           └── 2024-01-15-merhaba.md
│
├── themes/
│   └── my_theme/                     # Custom theme (optional)
│       ├── layouts/
│       │   └── post.html.eex         # Override post layout
│       └── assets/
│           └── css/
│               └── custom.css
│
├── lib/
│   └── my_website/
│       └── blocks/                   # Custom blocks
│           └── spotify.ex
│
├── static/                           # Static assets (copied as-is)
│   ├── images/
│   ├── fonts/
│   └── favicon.ico
│
├── output/                           # Generated static site
│
└── mix.exs
```

---

## Content Organization

### Directory-Based Content Types

Each directory under `content/` represents a content type:
- `posts/` — Blog posts (dated, longer form)
- `notes/` — Quick thoughts, TIL snippets
- `projects/` — Side projects showcase
- `talks/` — Presentations and talks
- `pages/` — Static pages (about, uses, etc.)

### Front Matter Schema

```yaml
---
title: "Building an Elixir SSG"           # Required
date: 2024-01-15                          # Required for posts/notes
updated: 2024-01-20                       # Optional, last updated date
lang: en                                  # Optional, defaults to site default
slug: custom-slug                         # Optional, overrides filename
description: "A brief description"        # Optional, for SEO/excerpts
categories: [elixir, tutorial]            # Optional
tags: [static-site, beginner]             # Optional
draft: false                              # Optional, defaults to false
featured: false                           # Optional, for highlighting
image: /images/cover.jpg                  # Optional, cover image
layout: custom_layout                     # Optional, override default layout
# Any custom fields go into `meta` map
my_custom_field: "value"                  # Accessible via content.meta["my_custom_field"]
---
```

### Content Structs

```elixir
# Raw struct — intermediate parsing (before markdown rendering)
%Sayfa.Content.Raw{
  path: "content/posts/2024-01-15-hello.md",
  front_matter: %{"title" => "Hello", "date" => ~D[2024-01-15]},
  body_markdown: "# Hello World\n\nContent here.",
  filename: "2024-01-15-hello.md"
}

# Content struct — final, ready for templates
%Sayfa.Content{
  title: "Building an Elixir SSG",
  body: "<h1>...</h1>",
  date: ~D[2024-01-15],
  slug: "building-an-elixir-ssg",
  source_path: "content/posts/2024-01-15-building-an-elixir-ssg.md",
  categories: ["elixir", "tutorial"],
  tags: ["static-site", "beginner"],
  draft: false,
  meta: %{
    "featured" => false,
    "image" => "/images/cover.jpg",
    "my_custom_field" => "value"
  }
}
```

### Filename Convention

```
# Posts/Notes (dated)
2024-01-15-my-post-title.md    →    /posts/my-post-title/

# Projects/Pages (undated)
my-project.md                   →    /projects/my-project/
about.md                        →    /about/
```

---

## URL Structure

| Content Type | URL Pattern | Example |
|--------------|-------------|---------|
| Posts | `/posts/{slug}/` | `/posts/building-elixir-ssg/` |
| Notes | `/notes/{slug}/` | `/notes/til-pattern-matching/` |
| Projects | `/projects/{slug}/` | `/projects/sayfa/` |
| Talks | `/talks/{slug}/` | `/talks/elixir-conf-2024/` |
| Pages | `/{slug}/` | `/about/` |
| Homepage | `/` | `/` |

**No dates in URLs** — keeps them clean and evergreen.

### Multilingual URLs (Subdirectory Approach)

```
English (default):  /posts/hello-world/
Turkish:            /tr/posts/merhaba-dunya/
```

### Special URLs

```
/feed.xml           # RSS feed (all posts)
/feed/posts.xml     # RSS feed (posts only)
/feed/notes.xml     # RSS feed (notes only)
/sitemap.xml        # Sitemap
/posts/             # Posts listing
/posts/page/2/      # Posts listing (paginated)
/categories/elixir/ # Category archive
/tags/tutorial/     # Tag archive
```

---

## Configuration

### Site Configuration (config/site.exs)

```elixir
import Config

config :my_website, :site,
  # Basic info
  title: "Furkan's Blog",
  description: "Software engineering, photography, and coffee",
  author: "Furkan",
  email: "hello@furkan.dev",
  base_url: "https://furkan.dev",

  # Multilingual
  default_lang: :en,
  languages: [
    en: [name: "English", path: ""],
    tr: [name: "Turkce", path: "/tr"]
  ],

  # Navigation
  nav: [
    %{label: "Blog", path: "/posts"},
    %{label: "Notes", path: "/notes"},
    %{label: "Projects", path: "/projects"},
    %{label: "About", path: "/about"}
  ],

  # Social links (for social_links block)
  social: [
    %{platform: :github, url: "https://github.com/furkan", icon: "github"},
    %{platform: :twitter, url: "https://twitter.com/furkan", icon: "twitter"},
    %{platform: :linkedin, url: "https://linkedin.com/in/furkan", icon: "linkedin"}
  ],

  # Content settings
  posts_per_page: 10,
  excerpt_length: 200,
  date_format: "%B %d, %Y",

  # Features
  enable_search: true,
  enable_rss: true,
  enable_sitemap: true,
  enable_dark_mode: true,

  # Theme
  theme: "default",

  # Blocks to enable
  blocks: [
    Sayfa.Blocks.Hero,
    Sayfa.Blocks.Header,
    Sayfa.Blocks.Footer,
    Sayfa.Blocks.SocialLinks,
    Sayfa.Blocks.RecentPosts,
    Sayfa.Blocks.TagCloud,
    Sayfa.Blocks.ReadingTime,
    Sayfa.Blocks.Toc,
    Sayfa.Blocks.CodeCopy
  ],

  # Build hooks
  hooks: []
```

---

## Extensibility System

### Block Behaviour

```elixir
defmodule Sayfa.Behaviours.Block do
  @moduledoc """
  Behaviour for creating reusable template components.

  Blocks are composable EEx components invoked via `@block.(:name, opts)` in templates.
  """

  @doc "Unique atom identifier for the block"
  @callback name() :: atom()

  @doc "Render the block with given assigns (site context merged with caller opts)"
  @callback render(assigns :: map()) :: String.t()

  @doc "Optional: Initialize block with config"
  @callback init(config :: map()) :: {:ok, map()} | {:error, term()}

  @optional_callbacks [init: 1]
end
```

### Example Block Implementation

```elixir
defmodule Sayfa.Blocks.ReadingTime do
  @behaviour Sayfa.Behaviours.Block

  @words_per_minute 200

  @impl true
  def name, do: :reading_time

  @impl true
  def render(%{content: content}) do
    words = content |> String.split(~r/\s+/) |> length()
    minutes = max(1, div(words, @words_per_minute))

    ~s(<span class="reading-time">#{minutes} min read</span>)
  end
end
```

### Hook Behaviour

```elixir
defmodule Sayfa.Behaviours.Hook do
  @moduledoc """
  Behaviour for build pipeline hooks.

  Hooks allow injecting custom logic at different stages of the build.
  """

  @type stage :: :before_parse | :after_parse | :before_render | :after_render | :before_write | :after_write

  @doc "Which build stage this hook runs at"
  @callback stage() :: stage()

  @doc "Execute the hook"
  @callback run(content :: term(), opts :: map()) :: {:ok, term()} | {:error, term()}

  @doc "Optional: Priority (lower = earlier). Default: 100"
  @callback priority() :: integer()

  @optional_callbacks [priority: 0]
end
```

### Content Type Behaviour

```elixir
defmodule Sayfa.Behaviours.ContentType do
  @callback name() :: atom()
  @callback directory() :: String.t()
  @callback url_prefix() :: String.t()
  @callback default_layout() :: String.t()
  @callback required_fields() :: [atom()]
end
```

### Theme Inheritance

Themes can inherit from other themes. Resolution order:
1. User's custom theme
2. Parent theme (if specified)
3. Default theme

```elixir
# In custom theme's theme.exs
config :my_theme,
  name: "My Custom Theme",
  parent: "default",
  description: "A minimal theme with custom colors"
```

---

## Default Theme Specification

### Design Principles
- Minimal, clean, documentation-style
- Mobile-first responsive
- Dark mode support
- Accessible (WCAG 2.1 AA)
- Fast loading (minimal JS)

### Color Scheme (TailwindCSS)

```css
/* Light mode */
--color-bg: #ffffff;
--color-text: #1f2937;
--color-text-muted: #6b7280;
--color-primary: #2563eb;
--color-border: #e5e7eb;
--color-code-bg: #f3f4f6;

/* Dark mode */
--color-bg: #111827;
--color-text: #f9fafb;
--color-text-muted: #9ca3af;
--color-primary: #60a5fa;
--color-border: #374151;
--color-code-bg: #1f2937;
```

### Typography
- Font stack: System fonts (fast loading)
- Headings: Semi-bold
- Body: Regular, 1.6 line height
- Code: Monospace, slightly smaller

### Layout
- Max content width: 768px
- Sticky header with nav
- Footer with social links

---

## Generated Output Structure

```
output/
├── index.html
├── posts/
│   ├── index.html
│   ├── hello-sayfa/
│   │   └── index.html
│   └── page/
│       └── 2/
│           └── index.html
├── notes/
│   └── index.html
├── projects/
│   └── index.html
├── categories/
│   └── meta/
│       └── index.html
├── tags/
│   ├── sayfa/
│   │   └── index.html
│   └── elixir/
│       └── index.html
├── about/
│   └── index.html
├── tr/
│   └── posts/
│       └── index.html
├── feed.xml
├── sitemap.xml
├── pagefind/
│   ├── pagefind.js
│   ├── pagefind-ui.js
│   ├── pagefind-ui.css
│   └── index/
└── assets/
    ├── css/
    │   └── theme.css
    └── images/
```

---

## CLI Commands

### mix sayfa.new

```bash
mix sayfa.new my_blog
mix sayfa.new my_blog --theme minimal --lang en,tr
```

### mix sayfa.build

```bash
mix sayfa.build
mix sayfa.build --output _site --drafts --verbose
mix sayfa.build --source test_site --output test_site/output
```

### mix sayfa.serve (Phase 6)

```bash
mix sayfa.serve
mix sayfa.serve --port 4000 --open --drafts
```

---

## Testing Strategy

### Unit Tests
- Content parsing (front matter + markdown)
- URL/slug generation
- Block rendering
- Feed generation
- Template rendering

### Integration Tests
- Full build pipeline
- Theme inheritance
- Hook execution order
- Multilingual content

### Example Test

```elixir
defmodule Sayfa.ContentTest do
  use ExUnit.Case

  describe "parse/1" do
    test "parses front matter and content" do
      markdown = """
      ---
      title: "Test Post"
      date: 2024-01-15
      tags: [elixir, test]
      custom_field: "custom value"
      ---

      # Hello World

      This is the content.
      """

      {:ok, content} = Sayfa.Content.parse(markdown)

      assert content.title == "Test Post"
      assert content.date == ~D[2024-01-15]
      assert content.tags == ["elixir", "test"]
      assert content.body =~ "<h1>Hello World</h1>"
      # Custom fields go to meta
      assert content.meta["custom_field"] == "custom value"
    end
  end
end
```

---

## Implementation Phases

### Phase 1: Core Parsing (DONE)

**Goal:** Parse markdown files with YAML front matter into structured Elixir data.

**Tasks:**

1. **Create Elixir project** — `mix new sayfa --module Sayfa`, set up `.gitignore`, `.formatter.exs`

2. **Configure `mix.exs`** — `elixir: "~> 1.18"`, deps: `{:mdex, "~> 0.2"}`, `{:yaml_elixir, "~> 2.9"}`, dev deps: `{:ex_doc, "~> 0.34"}`, `{:credo, "~> 1.7"}`, package metadata for Hex

3. **Implement `Sayfa.Markdown`** → `lib/sayfa/markdown.ex`
   - `render(markdown_string)` → `{:ok, html}` | `{:error, reason}`
   - `render!(markdown_string)` → html | raises
   - Configure MDEx with syntax highlighting enabled

4. **Implement `Sayfa.Content.Raw`** → `lib/sayfa/content/raw.ex`
   - Struct: `path`, `front_matter` (map), `body_markdown` (string), `filename`
   - `@enforce_keys [:path, :front_matter, :body_markdown]`

5. **Implement `Sayfa.Content`** → `lib/sayfa/content.ex`
   - Struct with known fields + `meta` catch-all
   - `parse(raw_string)` → splits front matter from markdown, returns `{:ok, %Content{}}`
   - `parse_file(file_path)` → reads file, delegates to `parse/1`
   - `from_raw(%Raw{})` → transforms Raw into Content
   - Slug generation from filename (strip date prefix, convert to kebab-case)

6. **Implement `Sayfa` main module** → `lib/sayfa.ex`
   - Public API delegating to submodules

7. **Write unit tests**
   - `test/sayfa/markdown_test.exs`
   - `test/sayfa/content_test.exs`
   - `test/sayfa/content/raw_test.exs`

**Files to create:**
```
lib/sayfa.ex
lib/sayfa/markdown.ex
lib/sayfa/content.ex
lib/sayfa/content/raw.ex
test/sayfa/markdown_test.exs
test/sayfa/content_test.exs
test/sayfa/content/raw_test.exs
```

**Verification:**
```bash
mix deps.get && mix compile && mix test
iex -S mix
iex> Sayfa.Markdown.render("# Hello **World**")
{:ok, "<h1>Hello <strong>World</strong></h1>\n"}
iex> Sayfa.Content.parse("---\ntitle: Test\n---\n# Hello")
{:ok, %Sayfa.Content{title: "Test", body: "<h1>Hello</h1>\n", ...}}
```

---

### Phase 2: Build Pipeline (DONE)

**Goal:** Orchestrate the full build from content files to HTML output.

**Tasks:**

1. **Implement `Sayfa.Config`** → `lib/sayfa/config.ex`
   - `get(key)` / `get(key, default)` — read from application config
   - Default values for: `title`, `base_url`, `content_dir`, `output_dir`, `theme`, `default_lang`
   - Support passing config as opts (for CLI overrides)

2. **Implement `Sayfa.Template`** → `lib/sayfa/template.ex`
   - `render(template_path, assigns)` → `{:ok, html}`
   - Layout wrapping: render content into layout, then layout into base
   - Inject `@block` helper function into assigns (stubbed initially)

3. **Create default theme** → `priv/default_theme/`
   - `layouts/base.html.eex` — HTML shell, `<head>`, `@inner_content`
   - `layouts/post.html.eex` — single post display
   - `layouts/page.html.eex` — generic page
   - `layouts/list.html.eex` — content listing
   - `layouts/home.html.eex` — home page (placeholder for blocks)

4. **Implement `Sayfa.Builder`** → `lib/sayfa/builder.ex`
   - `build(opts)` — full pipeline: load config, discover files, parse, filter drafts, render, write, copy assets
   - `clean(opts)` — remove output directory
   - Directory structure: content type → slug → `index.html`

5. **Implement `Mix.Tasks.Sayfa.Build`** → `lib/mix/tasks/sayfa.build.ex`
   - `mix sayfa.build` with options: `--source`, `--output`, `--drafts`, `--verbose`

6. **Write integration tests** — `test/sayfa/builder_test.exs`

**Files to create:**
```
lib/sayfa/config.ex
lib/sayfa/template.ex
lib/sayfa/builder.ex
lib/mix/tasks/sayfa.build.ex
priv/default_theme/layouts/base.html.eex
priv/default_theme/layouts/post.html.eex
priv/default_theme/layouts/page.html.eex
priv/default_theme/layouts/list.html.eex
priv/default_theme/layouts/home.html.eex
test/sayfa/config_test.exs
test/sayfa/template_test.exs
test/sayfa/builder_test.exs
```

**Verification:**
```bash
mkdir -p test_site/content/posts
echo '---\ntitle: "Hello"\ndate: 2024-01-15\n---\n# Hello World' > test_site/content/posts/hello.md
mix sayfa.build --source test_site --output test_site/output
cat test_site/output/posts/hello/index.html
```

---

### Phase 3: Content Types & Organization (DONE)

**Goal:** Support multiple content types, categories, tags, pagination, and layout selection.

**Tasks:**

1. **Content type behaviour** → `lib/sayfa/behaviours/content_type.ex`
   - Callbacks: `name/0`, `directory/0`, `url_prefix/0`, `default_layout/0`, `required_fields/0`

2. **Built-in content types** → `lib/sayfa/content_types/`
   - `post.ex` — `posts/`, dated, `layout: post`
   - `note.ex` — `notes/`, dated, `layout: post`
   - `project.ex` — `projects/`, undated, `layout: page`
   - `talk.ex` — `talks/`, undated, `layout: page`
   - `page.ex` — `pages/`, undated, `layout: page`

3. **Layout selection system** — read `layout:` from front matter, fall back to content type's `default_layout/0`, resolve from theme directory

4. **Categories and tags** — parse from front matter, generate archive pages: `/categories/{name}/`, `/tags/{name}/`

5. **Pagination** → `lib/sayfa/pagination.ex`
   - URL pattern: `/posts/page/2/`
   - Pagination assigns: `current_page`, `total_pages`, `prev_url`, `next_url`

6. **Collections API** → extend `Sayfa.Content`
   - `filter_by_type/2`, `filter_by_tag/2`, `sort_by_date/1`, `recent/2`

---

### Phase 4: Features & Feeds (DONE)

**Goal:** RSS feeds, sitemap, search, SEO, reading time, table of contents.

**Tasks:**

1. **RSS/Atom feeds** → `lib/sayfa/feed.ex` (dep: `{:xml_builder, "~> 2.2"}`)
2. **Sitemap** → `lib/sayfa/sitemap.ex`
3. **Pagefind integration** — run `pagefind --site <output_dir>` as post-build step
4. **SEO component** → `lib/sayfa/seo.ex` — meta tags, Open Graph, Twitter card tags
5. **Reading time** → `lib/sayfa/reading_time.ex`
6. **Table of contents** → `lib/sayfa/toc.ex`

---

### Phase 5: Extensibility & Blocks

**Goal:** Block system, hooks, themes, i18n, and project generator.

**Tasks:**

1. ~~**Block behaviour** → `lib/sayfa/behaviours/block.ex`~~ (DONE)
2. ~~**Block registry** → `lib/sayfa/block.ex`~~ (DONE)
3. ~~**`@block` helper integration** in `Sayfa.Template` — inject anonymous function into all template assigns~~ (DONE)
4. ~~**Built-in blocks** → `lib/sayfa/blocks/` — hero, recent_posts, tag_cloud, social_links, toc, reading_time, code_copy, header, footer~~ (DONE)
5. ~~**Hook behaviour** → `lib/sayfa/behaviours/hook.ex` — before/after parse/render stages~~ (DONE)
6. **Theme system** → `lib/sayfa/theme.ex` — loading, inheritance, asset merging
7. **Multilingual support** → `lib/sayfa/i18n.ex` — subdirectory approach
8. **Project generator** → `lib/mix/tasks/sayfa.new.ex`

**Verification:**
```bash
# In a template:
# <%= @block.(:hero, title: "Welcome", subtitle: "My Elixir Blog") %>
# <%= @block.(:recent_posts, limit: 3) %>
mix sayfa.build --source test_site --output test_site/output
# Verify hero section and recent posts appear in output HTML
```

---

### Phase 6: Developer Experience

**Goal:** Dev server, hot reload, caching, and developer tooling.

**Tasks:**

1. **Dev server** → `lib/mix/tasks/sayfa.serve.ex` (dep: `{:plug_cowboy, "~> 2.6"}`)
2. **File watching** (dep: `{:file_system, "~> 1.0"}`) — watch content/, themes/, config/
3. **Hot reload** — rebuild on file change, incremental builds
4. **Draft preview mode** — `mix sayfa.serve --drafts`
5. **Build caching** — cache parsed content, skip unchanged files
6. **Verbose logging** — `--verbose` flag, timing per build stage
7. **Error messages** — file path and line number in parse errors

---

## Implementation Order

Start with Phase 1 → Phase 2 → ... sequentially. Within each phase, follow the numbered task order. Each phase should be verified before moving to the next.

| Phase | Focus | Key Modules |
|-------|-------|-------------|
| **1** | Core Parsing (DONE) | Sayfa.Markdown, Sayfa.Content, Sayfa.Content.Raw |
| **2** | Build Pipeline | Sayfa.Config, Sayfa.Template, Sayfa.Builder, mix sayfa.build |
| **3** | Content Types | Multiple types, categories, tags, pagination |
| **4** | Features | RSS, sitemap, Pagefind search, SEO |
| **5** | Extensibility (Core DONE) | Blocks, hooks, themes, i18n, mix sayfa.new |
| **6** | DX | Dev server, hot reload, caching |

---

## Resources

- [MDEx Documentation](https://hexdocs.pm/mdex/)
- [Pagefind Documentation](https://pagefind.app/docs/)
- [TailwindCSS Standalone CLI](https://tailwindcss.com/blog/standalone-cli)
- [Elixir EEx Templates](https://hexdocs.pm/eex/EEx.html)
- [Tableau (Elixir SSG)](https://github.com/elixir-tools/tableau) - Reference implementation
- [NimblePublisher](https://github.com/dashbitco/nimble_publisher) - Simpler approach

---

## License

MIT License - Open source for everyone to use and contribute.
