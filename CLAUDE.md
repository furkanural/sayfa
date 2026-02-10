# CLAUDE.md - Sayfa Project Guidelines

This file provides context for Claude Code when working on the Sayfa project.

## Project Overview

**Sayfa** (Turkish for "page") is an open-source static site generator built in Elixir. It follows a two-layer architecture:

1. **Sayfa (this package)** - Reusable Hex package with core SSG functionality
2. **User sites** - Projects that depend on Sayfa via `{:sayfa, "~> x.x"}`

### Primary Goals
- Learn Elixir through building a real project
- Create a simple, extensible SSG tool
- Ship something usable quickly
- Allow others to build their own sites with Sayfa

## Requirements

| Requirement | Version | Notes |
|-------------|---------|-------|
| Elixir | ~> 1.18 | Latest features |
| OTP | 27+ | Required by Elixir 1.18 |
| Rust | Latest stable | Required for MDEx NIF compilation |

## Tech Stack

| Component | Library | Notes |
|-----------|---------|-------|
| Markdown | MDEx | Rust NIF, fast, built-in syntax highlighting. **No fallback** - Rust is required. |
| Front matter | YamlElixir | YAML parsing |
| Templates | EEx | Built-in Elixir templating |
| CSS | TailwindCSS CLI | Standalone, no Node.js |
| Search | Pagefind | Post-build indexing |

## Project Structure

```
sayfa/
├── lib/
│   ├── sayfa.ex                    # Main public API
│   ├── sayfa/
│   │   ├── builder.ex              # Core build pipeline
│   │   ├── content.ex              # Content loading/parsing
│   │   ├── content/
│   │   │   └── raw.ex              # Raw parsed content struct
│   │   ├── markdown.ex             # MDEx wrapper
│   │   ├── template.ex             # EEx rendering
│   │   ├── feed.ex                 # RSS generation
│   │   ├── sitemap.ex              # Sitemap generation
│   │   ├── i18n.ex                 # Multilingual support
│   │   ├── config.ex               # Configuration handling
│   │   ├── theme.ex                # Theme loading
│   │   │
│   │   ├── behaviours/             # Extension contracts
│   │   │   ├── block.ex
│   │   │   ├── hook.ex
│   │   │   └── content_type.ex
│   │   │
│   │   ├── block_registry.ex       # Block name → module lookup
│   │   │
│   │   ├── blocks/                 # Built-in blocks (reusable EEx components)
│   │   │   ├── hero.ex
│   │   │   ├── header.ex
│   │   │   ├── footer.ex
│   │   │   ├── social_links.ex
│   │   │   ├── toc.ex
│   │   │   ├── recent_posts.ex
│   │   │   ├── tag_cloud.ex
│   │   │   ├── reading_time.ex
│   │   │   └── code_copy.ex
│   │   │
│   │   └── content_types/          # Built-in content types
│   │       ├── post.ex
│   │       ├── note.ex
│   │       ├── project.ex
│   │       ├── talk.ex
│   │       └── page.ex
│   │
│   └── mix/tasks/                  # CLI commands
│       ├── sayfa.new.ex
│       ├── sayfa.build.ex
│       └── sayfa.serve.ex
│
├── priv/
│   ├── templates/new_site/         # mix sayfa.new template
│   └── default_theme/              # Default theme files
│
└── test/
```

## Code Conventions

### Module Naming
- Main modules: `Sayfa.ModuleName`
- Behaviours: `Sayfa.Behaviours.BehaviourName`
- Blocks: `Sayfa.Blocks.BlockName`
- Content types: `Sayfa.ContentTypes.TypeName`
- Mix tasks: `Mix.Tasks.Sayfa.TaskName`

### Function Naming
- Use `!` suffix for functions that raise on error: `parse!`, `build!`
- Use `?` suffix for boolean functions: `draft?`, `published?`
- Prefer `verb_noun` pattern: `parse_content`, `render_template`, `build_site`

### Documentation
- Every public module needs `@moduledoc`
- Every public function needs `@doc` with examples
- Add `@spec` typespecs to all public functions
- Use `## Examples` section in docs

```elixir
@doc """
Parses markdown content with front matter.

## Examples

    iex> Sayfa.Content.parse("---\\ntitle: Hello\\n---\\n# World")
    {:ok, %Sayfa.Content{title: "Hello", body: "<h1>World</h1>"}}

"""
@spec parse(String.t()) :: {:ok, Content.t()} | {:error, term()}
def parse(markdown) do
  # ...
end
```

### Error Handling
- Return `{:ok, result}` or `{:error, reason}` tuples
- Provide `!` variants that raise for convenience
- Use custom exception modules for specific errors

```elixir
defmodule Sayfa.ParseError do
  defexception [:message, :file, :line]
end
```

### Structs
- Define structs with `@enforce_keys` for required fields
- Add `@type t` for the struct type
- Use `defstruct` with default values

```elixir
defmodule Sayfa.Content do
  @enforce_keys [:title, :body]
  defstruct [
    :title,
    :body,
    :date,
    :slug,
    :lang,
    :source_path,
    categories: [],
    tags: [],
    draft: false,
    meta: %{}  # Catch-all for custom front matter fields
  ]

  @type t :: %__MODULE__{
    title: String.t(),
    body: String.t(),
    date: Date.t() | nil,
    slug: String.t() | nil,
    lang: atom(),
    source_path: String.t() | nil,
    categories: [String.t()],
    tags: [String.t()],
    draft: boolean(),
    meta: map()
  }
end

# Raw struct for intermediate parsing (before markdown rendering)
defmodule Sayfa.Content.Raw do
  @enforce_keys [:path, :front_matter, :body_markdown]
  defstruct [:path, :front_matter, :body_markdown, :filename]

  @type t :: %__MODULE__{
    path: String.t(),
    front_matter: map(),
    body_markdown: String.t(),
    filename: String.t() | nil
  }
end
```

## Key Design Patterns

### Content Pipeline
Content flows through these stages:
1. **Load** - Read files from disk
2. **Parse** - Extract front matter + markdown → `Sayfa.Content.Raw`
3. **Transform** - Apply hooks, generate slugs, render markdown → `Sayfa.Content`
4. **Render** - Apply EEx templates
5. **Write** - Output to disk

### Two-Struct Design (Raw → Content)

The content parsing uses two structs for a cleaner pipeline:

1. **`Sayfa.Content.Raw`** - Intermediate representation after file parsing
   - Contains: path, front_matter (map), body_markdown (string), filename
   - Used for: Hooks that need raw markdown, caching, lazy rendering

2. **`Sayfa.Content`** - Final content ready for templates
   - Contains: title, body (HTML), date, slug, tags, categories, meta
   - Used for: Template rendering, collections, queries

This separation allows hooks to modify content before markdown rendering.

### Block System (Reusable EEx Components)

Blocks replace the original "widgets" concept. A block is a reusable EEx component invoked via a helper function injected into template assigns.

**How it works:**
1. Blocks implement `Sayfa.Behaviours.Block` with `name/0` and `render/1` callbacks
2. `Sayfa.BlockRegistry` maps atom names → block modules
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
    # Return HTML string using EEx or string interpolation
  end
end
```

### Layout Composition (Three-Layer Rendering)

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
- `home.html.eex` → hero + recent_posts + tag_cloud
- `post.html.eex` → reading_time + toc + content + social_links
- `about.html.eex` → content only (minimal)
- `list.html.eex` → pagination + post cards
- `page.html.eex` → generic page wrapper

Users can create custom layouts in their theme directory.

### Behaviours for Extensibility
Users extend Sayfa by implementing behaviours:

```elixir
# Block behaviour
defmodule Sayfa.Behaviours.Block do
  @callback name() :: atom()
  @callback render(assigns :: map()) :: String.t()
end

# Hook behaviour
defmodule Sayfa.Behaviours.Hook do
  @callback stage() :: :before_parse | :after_parse | :before_render | :after_render
  @callback run(content :: term(), opts :: map()) :: {:ok, term()} | {:error, term()}
end
```

### Configuration
Site config lives in user's `config/site.exs`:

```elixir
config :my_site, :sayfa,
  title: "My Site",
  base_url: "https://example.com",
  # ...
```

Access via `Sayfa.Config.get/1`:

```elixir
title = Sayfa.Config.get(:title)
```

## Common Tasks

### Running Tests
```bash
mix test                    # Run all tests
mix test test/sayfa/content_test.exs  # Run specific file
mix test --cover            # With coverage
```

### Building Documentation
```bash
mix docs
open doc/index.html
```

### Linting
```bash
mix credo --strict
mix format --check-formatted
```

### Local Development
```bash
# In a test site directory
mix deps.get
mix sayfa.build
mix sayfa.serve  # If implemented
```

## URL Conventions

| Content Type | URL Pattern |
|--------------|-------------|
| Posts | `/posts/{slug}/` |
| Notes | `/notes/{slug}/` |
| Projects | `/projects/{slug}/` |
| Talks | `/talks/{slug}/` |
| Pages | `/{slug}/` |
| Turkish | `/tr/posts/{slug}/` |

**No dates in URLs** - keeps them clean and evergreen.

## Front Matter Schema

```yaml
---
title: "Required title"           # Required
date: 2024-01-15                  # Required for posts/notes
updated: 2024-01-20               # Optional
lang: en                          # Optional (default: site default)
slug: custom-slug                 # Optional (default: from filename)
description: "For SEO"            # Optional
categories: [cat1, cat2]          # Optional
tags: [tag1, tag2]                # Optional
draft: false                      # Optional (default: false)
featured: false                   # Optional
image: /images/cover.jpg          # Optional
layout: custom_layout             # Optional
---
```

## Testing Guidelines

### Unit Tests
- Test each module in isolation
- Mock external dependencies (file system, MDEx)
- Use doctest for simple examples

```elixir
defmodule Sayfa.ContentTest do
  use ExUnit.Case, async: true
  doctest Sayfa.Content

  describe "parse/1" do
    test "extracts front matter" do
      # ...
    end

    test "returns error for invalid YAML" do
      # ...
    end
  end
end
```

### Integration Tests
- Test full build pipeline
- Use temporary directories
- Clean up after tests

```elixir
defmodule Sayfa.BuilderIntegrationTest do
  use ExUnit.Case

  @tmp_dir "test/tmp"

  setup do
    File.mkdir_p!(@tmp_dir)
    on_exit(fn -> File.rm_rf!(@tmp_dir) end)
    :ok
  end
end
```

## Git Workflow

### Branch Naming
- `feature/short-description`
- `fix/issue-description`
- `docs/what-changed`

### Commit Messages
Follow conventional commits:
- `feat: add RSS feed generation`
- `fix: handle empty front matter`
- `docs: add widget examples`
- `refactor: simplify build pipeline`
- `test: add content parser tests`

## Dependencies

### Phase 1 (minimal)
```elixir
{:mdex, "~> 0.2"},            # Markdown parsing (check hex.pm for latest)
{:yaml_elixir, "~> 2.9"},     # YAML front matter
```

### Phase 2+
```elixir
{:slugify, "~> 1.3"},         # URL slugs
{:timex, "~> 3.7"},           # Date handling
{:xml_builder, "~> 2.2"},     # RSS/Sitemap XML
```

### Dev dependencies (all phases)
```elixir
{:ex_doc, "~> 0.34", only: :dev, runtime: false},
{:credo, "~> 1.7", only: [:dev, :test], runtime: false},
```

### Later phases
```elixir
{:file_system, "~> 1.0"},     # File watching (Phase 5)
{:plug_cowboy, "~> 2.6"},     # Dev server (Phase 5)
{:image, "~> 0.37"},          # Image optimization (Phase 4)
```

## Performance Considerations

- Use `Stream` for processing large numbers of files
- Cache parsed content during dev server
- MDEx is already fast (Rust NIF)
- Pagefind runs post-build, doesn't affect build time

## Common Gotchas

1. **MDEx requires Rust** - Users need Rust installed for NIF compilation
2. **EEx templates** - Remember to use `<%= %>` for output, `<% %>` for logic
3. **File paths** - Use `Path.join/2` for cross-platform compatibility
4. **Front matter dates** - YamlElixir returns Date structs, not strings
5. **Slug generation** - Handle Unicode properly with Slugify

## Asking for Help

When stuck, provide:
1. The error message (full stack trace)
2. The relevant code
3. What you expected to happen
4. What actually happened

## Phase Status

Track implementation progress:
- [x] Phase 1: Core Parsing
  - [x] Create Elixir project with mix
  - [x] Configure mix.exs (mdex, yaml_elixir, ex_doc, credo)
  - [x] Implement Sayfa.Markdown (MDEx wrapper)
  - [x] Implement Sayfa.Content.Raw struct
  - [x] Implement Sayfa.Content (parsing + rendering)
  - [x] Implement Sayfa main module (public API)
  - [x] Write unit tests
- [ ] Phase 2: Build Pipeline
  - [ ] Implement Sayfa.Config
  - [ ] Implement Sayfa.Template (EEx rendering, @block stub)
  - [ ] Create default theme layouts (base, post, page, list, home)
  - [ ] Implement Sayfa.Builder (orchestration)
  - [ ] Implement mix sayfa.build task
  - [ ] Write integration tests
- [ ] Phase 3: Content Types & Organization
  - [ ] Content type behaviour + built-in types (post, note, project, talk, page)
  - [ ] Layout selection system (front matter → layout template)
  - [ ] Categories and tags (archive pages)
  - [ ] Pagination
  - [ ] Collections API (filter, sort, recent)
- [ ] Phase 4: Features & Feeds
  - [ ] RSS/Atom feeds
  - [ ] Sitemap generation
  - [ ] Pagefind search integration
  - [ ] SEO meta tags
  - [ ] Reading time calculation
  - [ ] Table of contents extraction
- [ ] Phase 5: Extensibility & Blocks
  - [ ] Block behaviour + BlockRegistry
  - [ ] @block helper integration in templates
  - [ ] Built-in blocks (hero, recent_posts, tag_cloud, social_links, toc, reading_time, code_copy, header, footer)
  - [ ] Hook behaviour (before/after parse/render/write)
  - [ ] Theme system (loading, inheritance)
  - [ ] Multilingual support (i18n)
  - [ ] Project generator (mix sayfa.new)
- [ ] Phase 6: Developer Experience
  - [ ] Dev server (mix sayfa.serve)
  - [ ] File watching + hot reload
  - [ ] Draft preview mode
  - [ ] Build caching
  - [ ] Verbose logging + error messages

## Verification Commands

### Phase 1a Verification
```bash
mix deps.get
mix compile
mix test

# Manual test in IEx
iex -S mix
iex> Sayfa.Markdown.render("# Hello **World**")
{:ok, "<h1>Hello <strong>World</strong></h1>\n"}

iex> Sayfa.Content.parse("---\\ntitle: Test\\n---\\n# Hello")
{:ok, %Sayfa.Content{title: "Test", body: "<h1>Hello</h1>\n", ...}}
```

### Phase 1b Verification
```bash
# Create test content
mkdir -p test_site/content/posts
echo '---\ntitle: "Hello"\n---\n# Hello World' > test_site/content/posts/hello.md

# Build
mix sayfa.build --source test_site --output test_site/output

# Verify output
cat test_site/output/posts/hello/index.html
```

---

*This file helps Claude Code understand Sayfa's architecture and conventions. Update it as the project evolves.*
