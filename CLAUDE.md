# CLAUDE.md - Sayfa Project Guidelines

## Project Overview

**Sayfa** (Turkish for "page") is an open-source static site generator built in Elixir (v0.1.0). It follows a two-layer architecture:

1. **Sayfa (this package)** — Reusable Hex package with core SSG functionality
2. **User sites** — Projects that depend on Sayfa via `{:sayfa, "~> x.x"}`

Goals: Learn Elixir, create a simple/extensible SSG, ship something usable, allow others to build sites with Sayfa.

## Requirements

| Requirement | Version | Source |
|-------------|---------|--------|
| Elixir | 1.19.5 | `mise.toml` |
| OTP | 28 | `mise.toml` |
| Rust | 1.93.0 (stable) | `mise.toml` — required for MDEx NIF |

## Tech Stack

| Component | Library | Notes |
|-----------|---------|-------|
| Markdown | MDEx | Rust NIF, fast, built-in syntax highlighting |
| Front matter | YamlElixir | YAML parsing |
| Templates | EEx | Built-in Elixir templating |
| Slugs | Slugify | URL slug generation |
| XML | XmlBuilder | RSS/Atom feeds, sitemap |
| Dev server | Plug + Cowboy | Optional dependency |
| File watching | FileSystem | Optional dependency |

## Project Structure

```
sayfa/
├── lib/
│   ├── sayfa.ex                    # Main public API
│   ├── sayfa/
│   │   ├── builder.ex              # Core build pipeline orchestration
│   │   ├── config.ex               # Configuration handling
│   │   ├── content.ex              # Content loading/parsing → Content struct
│   │   ├── content/
│   │   │   └── raw.ex              # Raw parsed content struct (intermediate)
│   │   ├── content_type.ex         # Content type registry & routing
│   │   ├── markdown.ex             # MDEx wrapper
│   │   ├── template.ex             # EEx rendering
│   │   ├── theme.ex                # Theme loading & inheritance
│   │   ├── block.ex                # Block registry (name → module lookup)
│   │   ├── feed.ex                 # RSS/Atom generation
│   │   ├── sitemap.ex              # Sitemap generation
│   │   ├── seo.ex                  # SEO meta tags
│   │   ├── pagination.ex           # Pagination support
│   │   ├── reading_time.ex         # Reading time calculation
│   │   ├── toc.ex                  # Table of contents extraction
│   │   ├── i18n.ex                 # Multilingual support
│   │   │
│   │   ├── behaviours/             # Extension contracts
│   │   │   ├── block.ex            # Block behaviour
│   │   │   ├── hook.ex             # Hook behaviour
│   │   │   └── content_type.ex     # Content type behaviour
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
│   │   ├── content_types/          # Built-in content types
│   │   │   ├── post.ex
│   │   │   ├── note.ex
│   │   │   ├── project.ex
│   │   │   ├── talk.ex
│   │   │   └── page.ex
│   │   │
│   │   └── dev_server/             # Development server
│   │       ├── supervisor.ex       # Supervision tree
│   │       ├── plug.ex             # HTTP request handling
│   │       ├── watcher.ex          # File system watcher
│   │       └── rebuilder.ex        # Incremental rebuild on change
│   │
│   └── mix/tasks/                  # CLI commands
│       ├── sayfa.new.ex            # Project generator
│       ├── sayfa.build.ex          # Build site
│       └── sayfa.serve.ex          # Dev server
│
├── priv/
│   ├── templates/new_site/         # mix sayfa.new scaffolding
│   └── default_theme/
│       └── layouts/                # base, home, list, page, post
│
└── test/
```

## Code Conventions

### Module Naming
- Main modules: `Sayfa.ModuleName`
- Behaviours: `Sayfa.Behaviours.BehaviourName`
- Blocks: `Sayfa.Blocks.BlockName`
- Content types: `Sayfa.ContentTypes.TypeName`
- Dev server: `Sayfa.DevServer.ModuleName`
- Mix tasks: `Mix.Tasks.Sayfa.TaskName`

### Function Naming
- `!` suffix for functions that raise: `parse!`, `build!`
- `?` suffix for boolean functions: `draft?`, `published?`
- Prefer `verb_noun` pattern: `parse_content`, `render_template`, `build_site`

### Documentation
- Every public module needs `@moduledoc`
- Every public function needs `@doc` with `## Examples`
- Add `@spec` typespecs to all public functions

### Error Handling
- Return `{:ok, result}` or `{:error, reason}` tuples
- Provide `!` variants that raise for convenience
- Use custom exception modules for specific errors

### Structs
- Define structs with `@enforce_keys` for required fields
- Add `@type t` for the struct type
- Use `defstruct` with default values

## Key Design Patterns

### Content Pipeline

Content flows through these stages:

1. **Load** — Read files from disk
2. **Parse** — Extract front matter + markdown → `Sayfa.Content.Raw`
3. **Transform** — Apply hooks, generate slugs, render markdown → `Sayfa.Content`
4. **Render** — Apply EEx templates (layout → base)
5. **Write** — Output to disk

### Two-Struct Design (Raw → Content)

- **`Sayfa.Content.Raw`** — Intermediate: path, front_matter (map), body_markdown (string), filename
- **`Sayfa.Content`** — Final: title, body (HTML), date, slug, tags, categories, meta

This separation allows hooks to modify content before markdown rendering.

### Block System

`Sayfa.Block` maps atom names → block modules. A `@block` function is injected into every template's assigns.

```elixir
# In templates:
<%= @block.(:hero, title: "Welcome") %>
<%= @block.(:recent_posts, limit: 5) %>
```

Blocks implement `Sayfa.Behaviours.Block` with `name/0` and `render/1` callbacks.

### Layout Composition (Three-Layer)

1. **Content body** — markdown rendered to HTML
2. **Layout template** — wraps content, places blocks (selected via `layout:` front matter)
3. **Base template** — HTML shell (`<html>`, `<head>`), inserts `@inner_content`

Available layouts: `home`, `post`, `page`, `list` (plus custom user layouts).

### Behaviours for Extensibility

- `Sayfa.Behaviours.Block` — `name/0`, `render/1`
- `Sayfa.Behaviours.Hook` — `stage/0`, `run/2` (stages: `:before_parse`, `:after_parse`, `:before_render`, `:after_render`)
- `Sayfa.Behaviours.ContentType` — content type contracts

### Configuration

Site config lives in user's `config/site.exs`, accessed via `Sayfa.Config.get/1`.

## Development Workflow

### Before Committing

All four must pass before committing:

```bash
mix compile --warnings-as-errors
mix format --check-formatted
mix credo --strict
mix test
```

These are the same checks CI runs. Fix any issues before pushing.

### Running Tests

```bash
mix test                              # All tests
mix test test/sayfa/content_test.exs  # Specific file
mix test --cover                      # With coverage
```

### Linting

```bash
mix format            # Auto-format
mix credo --strict    # Static analysis
```

### Building Documentation

```bash
mix docs
open doc/index.html
```

### Dev Server

```bash
mix sayfa.serve  # Starts dev server with file watching + hot reload
```

The dev server is built on `Sayfa.DevServer.Supervisor` which manages:
- `Sayfa.DevServer.Plug` — HTTP request handling via Plug/Cowboy
- `Sayfa.DevServer.Watcher` — File system monitoring
- `Sayfa.DevServer.Rebuilder` — Incremental rebuilds on file changes

## CI/CD

### GitHub Actions

**CI** (`.github/workflows/ci.yml`) — Runs on push/PR to `main`:
1. Setup Rust 1.93.0, Elixir 1.19.5/OTP 28
2. Cache deps and `_build`
3. `mix compile --warnings-as-errors`
4. `mix format --check-formatted`
5. `mix credo --strict`
6. `mix test`

**Release** (`.github/workflows/release.yml`) — Runs on `v*` tags:
1. Setup Rust + Elixir/OTP
2. `mix hex.publish --yes` (requires `HEX_API_KEY` secret)

### Dependabot

Configured in `.github/dependabot.yml` — weekly updates for:
- Mix dependencies
- GitHub Actions

## URL Conventions

| Content Type | URL Pattern |
|--------------|-------------|
| Posts | `/posts/{slug}/` |
| Notes | `/notes/{slug}/` |
| Projects | `/projects/{slug}/` |
| Talks | `/talks/{slug}/` |
| Pages | `/{slug}/` |
| Turkish | `/tr/posts/{slug}/` |

No dates in URLs — keeps them clean and evergreen.

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

- Test each module in isolation with `async: true`
- Mock external dependencies (file system, MDEx)
- Use doctest for simple examples
- Integration tests use temporary directories with `on_exit` cleanup
- Follow `describe "function/arity"` → `test "specific case"` structure

## Git Workflow

### Branch Naming
- `feature/short-description`
- `fix/issue-description`
- `docs/what-changed`

### Commit Messages
Follow conventional commits: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `style:`, `chore:`

## Dependencies

From `mix.exs`:

```elixir
# Core
{:mdex, "~> 0.2"},                                      # Markdown (Rust NIF)
{:yaml_elixir, "~> 2.9"},                               # YAML front matter
{:slugify, "~> 1.3"},                                   # URL slugs
{:xml_builder, "~> 2.2"},                               # RSS/Sitemap XML

# Optional
{:plug_cowboy, "~> 2.7", optional: true},               # Dev server
{:file_system, "~> 1.0", optional: true},               # File watching

# Dev/Test only
{:ex_doc, "~> 0.34", only: :dev, runtime: false},       # Documentation
{:credo, "~> 1.7", only: [:dev, :test], runtime: false}  # Linting
```

## Common Gotchas

1. **MDEx requires Rust** — Users need Rust installed for NIF compilation
2. **EEx templates** — Use `<%= %>` for output, `<% %>` for logic
3. **File paths** — Use `Path.join/2` for cross-platform compatibility
4. **Front matter dates** — YamlElixir returns Date structs, not strings
5. **Slug generation** — Handle Unicode properly with Slugify
6. **Optional deps** — `plug_cowboy` and `file_system` are optional; dev server features require them
