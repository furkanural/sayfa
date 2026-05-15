# CLAUDE.md - Sayfa Project Guidelines

## Quick Start

Default workflow for most tasks:

1. **Clarify scope** — Confirm the task boundaries (bug fix, feature, refactor)
2. **Locate files** — Use `Glob`/`Grep` to find relevant modules/templates
3. **Read selectively** — Inspect only the 2–3 most relevant files
4. **Make focused edits** — Use `Edit` for surgical changes; avoid rewrites
5. **Verify iteratively** — Run targeted tests for touched modules
6. **Final check** — Run the pre-commit gate before finishing

**Response template for completed work:**
1. What changed and why
2. Files touched
3. Validation performed
4. Follow-ups/risks (if any)

---

## Non-Negotiables

### Pre-Commit Gate (CI Parity)

All four must pass before committing. These match CI exactly:

```bash
mix compile --warnings-as-errors
mix format --check-formatted
mix credo --strict
mix test
```

### JavaScript Minification

When modifying `priv/default_theme/assets/js/enhancements.js`, manually update `enhancements.min.js`:

- Keep section comments (`/* 1. Reading progress bar */`)
- Remove other comments/whitespace
- Shorten variable names within each IIFE
- Keep each feature on a separate line
- Example: `var article = document.querySelector("article");` → `var a=document.querySelector("article");`

### Commit Messages

Follow conventional commits: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `style:`, `chore:`

---

## Claude Code Tool Strategy

Deterministic order to minimize unnecessary exploration:

| Phase | Tool | Purpose |
|-------|------|---------|
| Discovery | `Glob` / `Grep` | Find files by pattern or content |
| Inspection | `Read` | Read 2–3 key files to confirm direction |
| Changes | `Edit` | Prefer surgical edits over rewrites |
| Execution | `Bash` | Shell commands only when no dedicated tool applies |

**Parallelism**: Make independent calls in parallel; never chain dependent calls.

**Stopping rule**: Once 2–3 key files confirm the direction, stop exploring and act.

---

## Implementation Workflow

### Small Tasks (single module)
- Locate → Read → Edit → Run targeted test

### Medium Tasks (cross-module)
- Locate all affected files in parallel
- Read key files
- Make edits
- Run tests for all touched modules

### Large Tasks (architectural)
- Consider entering plan mode
- Follow the full verification ladder

---

## Verification Levels

### Iteration Checks (while developing)
Run targeted tests for files you're touching:

```bash
mix test test/sayfa/content_test.exs          # specific module
mix test test/sayfa/blocks/header_test.exs    # specific block
```

### Pre-Commit Checks (before finishing)
Run the full gate:

```bash
mix compile --warnings-as-errors
mix format --check-formatted
mix credo --strict
mix test
```

---

## Architecture Highlights

**Sayfa** is an Elixir static site generator (v0.4.2) with a two-layer architecture:
1. **Sayfa (this package)** — Reusable Hex package with core SSG functionality
2. **User sites** — Projects that depend on Sayfa via `{:sayfa, "~> x.x"}`

### Content Pipeline

Content flows through 12 stages: resolve config → discover files → parse → classify → filter drafts → validate → enrich → render → archives → indexes → feeds → sitemap.

Key structs:
- **`Sayfa.Content.Raw`** — Intermediate (path, front_matter, body_markdown)
- **`Sayfa.Content`** — Final (title, body HTML, slug, tags, etc.)

### Block System

Templates call `<%= @block.(:toc) %>` or `<%= @block.(:recent_content, limit: 5) %>`.
Blocks implement `Sayfa.Behaviours.Block` with `name/0` and `render/1`.

### Layout Composition (Three-Layer)
1. Content body (markdown → HTML)
2. Layout template (wraps content, places blocks)
3. Base template (HTML shell with `@inner_content`)

### Internationalization

`Sayfa.I18n` handles translations:
- Lookup chain: config overrides → lang YAML → default YAML → key
- Auto-link translations across language directories
- Templates use `<%= @t.("key") %>`
- RTL support for Arabic, Hebrew, Farsi, Urdu

See [Appendix: Project Structure](#project-structure) for full tree.

---

## Common Gotchas

- [ ] **MDEx requires Rust** — Users need Rust 1.95.0+ for NIF compilation
- [ ] **EEx templates** — Use `<%= %>` for output, `<% %>` for logic
- [ ] **File paths** — Use `Path.join/2` for cross-platform compatibility
- [ ] **Front matter dates** — YamlElixir returns Date structs, not strings
- [ ] **Slug generation** — Handle Unicode properly with Slugify
- [ ] **Optional deps** — `plug_cowboy` and `file_system` are optional; dev server requires them
- [ ] **TailwindCSS** — `tailwind` is a runtime: false dependency; compilation happens at build time
- [ ] **Asset fingerprinting** — Skipped in dev mode to prevent CSS loss on hot reload

---

## Appendix

### Project Structure

```
lib/
├── sayfa.ex                    # Main public API
├── sayfa/
│   ├── builder.ex              # Build pipeline (12 stages)
│   ├── config.ex               # Configuration
│   ├── content.ex              # Content loading/parsing
│   ├── content/
│   │   └── raw.ex              # Raw parsed content struct
│   ├── content_type.ex         # Content type registry
│   ├── markdown.ex             # MDEx wrapper
│   ├── template.ex             # EEx rendering
│   ├── theme.ex                # Theme loading
│   ├── block.ex                # Block registry
│   ├── tailwind.ex             # TailwindCSS compilation
│   ├── feed.ex                 # Atom/JSON feed generation
│   ├── sitemap.ex              # Sitemap generation
│   ├── seo.ex                  # SEO meta tags
│   ├── pagination.ex           # Pagination
│   ├── reading_time.ex         # Reading time
│   ├── toc.ex                  # Table of contents generation
│   ├── i18n.ex                 # Multilingual support
│   ├── excerpt.ex              # Content excerpt generation
│   ├── date_format.ex          # Locale-aware date formatting
│   ├── image.ex                # Image handling
│   ├── validator.ex            # Content validation
│   ├── behaviours/             # Extension contracts
│   │   ├── block.ex
│   │   ├── hook.ex
│   │   └── content_type.ex
│   ├── blocks/                 # Built-in blocks (14)
│   │   ├── header.ex
│   │   ├── footer.ex
│   │   ├── social_links.ex
│   │   ├── toc.ex
│   │   ├── tag_cloud.ex
│   │   ├── category_cloud.ex
│   │   ├── cloud.ex            # Shared cloud rendering logic
│   │   ├── reading_time.ex
│   │   ├── code_copy.ex
│   │   ├── recent_content.ex   # Groups all content types
│   │   ├── copy_link.ex
│   │   ├── breadcrumb.ex
│   │   ├── language_switcher.ex
│   │   ├── related_content.ex
│   │   ├── analytics.ex
│   │   └── helpers.ex          # Shared block helpers
│   ├── content_types/          # Built-in content types (5)
│   │   ├── article.ex
│   │   ├── note.ex
│   │   ├── project.ex
│   │   ├── talk.ex
│   │   ├── page.ex
│   │   └── base.ex             # Macro for content type definitions
│   ├── hooks/                  # Built-in hooks
│   │   └── responsive_images.ex  # Rewrites <img> to <picture> with WebP/AVIF
│   └── dev_server/             # Dev server (optional deps)
│       ├── supervisor.ex
│       ├── plug.ex
│       ├── watcher.ex
│       └── rebuilder.ex
└── mix/tasks/                  # CLI commands (11 tasks)
    ├── sayfa.new.ex
    ├── sayfa.build.ex
    ├── sayfa.clean.ex          # Remove build output directory
    ├── sayfa.serve.ex
    ├── sayfa.upgrade.ex        # Sync new theme files from package
    ├── sayfa.gen.layout.ex
    ├── sayfa.gen.content.ex
    ├── sayfa.gen.block.ex
    ├── sayfa.gen.content_type.ex
    ├── sayfa.gen.images.ex
    └── sayfa.gen.lang.ex       # Add a new language to an existing site

priv/
├── templates/
│   ├── new_site/               # mix sayfa.new scaffolding
│   ├── gen_block/              # Block generator template
│   ├── gen_content_type/       # Content type generator template
│   └── gen_images/             # Image optimization templates
├── translations/               # 14 built-in UI languages
└── default_theme/
    ├── layouts/                # 9 layouts
    │   ├── 404.html.eex
    │   ├── article.html.eex
    │   ├── base.html.eex
    │   ├── home.html.eex
    │   ├── list.html.eex
    │   ├── note.html.eex
    │   ├── page.html.eex
    │   ├── project.html.eex
    │   └── talk.html.eex
    └── assets/
        ├── css/
        │   ├── main.css
        │   └── vendor/
        │       └── catppuccin-mocha.css
        └── js/
            ├── enhancements.js
            └── enhancements.min.js
```

### Code Conventions

**Module Naming:**
- Main: `Sayfa.ModuleName`
- Behaviours: `Sayfa.Behaviours.BehaviourName`
- Blocks: `Sayfa.Blocks.BlockName`
- Content types: `Sayfa.ContentTypes.TypeName`
- Mix tasks: `Mix.Tasks.Sayfa.TaskName`
- Hooks: `Sayfa.Hooks.HookName`

**Function Naming:**
- `!` suffix for raising functions: `parse!`, `build!`
- `?` suffix for booleans: `draft?`, `published?`
- Prefer `verb_noun`: `parse_content`, `render_template`

**Documentation:**
- Every public module needs `@moduledoc`
- Every public function needs `@doc` with `## Examples`
- Add `@spec` typespecs to all public functions

**Error Handling:**
- Return `{:ok, result}` or `{:error, reason}` tuples
- Provide `!` variants for convenience

**Structs:**
- Define with `@enforce_keys` for required fields
- Add `@type t` for struct type

### Behaviours for Extensibility

- `Sayfa.Behaviours.Block` — `name/0`, `render/1`
- `Sayfa.Behaviours.Hook` — `stage/0`, `run/2` (stages: `:before_parse`, `:after_parse`, `:before_render`, `:after_render`)
- `Sayfa.Behaviours.ContentType` — `name/0`, `directory/0`, `url_prefix/0`, `default_layout/0`, `required_fields/0`

### Configuration

Site config lives in user's `config/site.exs`, accessed via `Sayfa.Config.get/1`.

### Development Commands

```bash
mix format            # Auto-format
mix credo --strict    # Static analysis
mix docs              # Build documentation
mix sayfa.serve       # Dev server with hot reload
```

### Testing Guidelines

- Test each module in isolation with `async: true`
- Mock external dependencies (file system, MDEx)
- Use doctest for simple examples
- Integration tests use temporary directories with `on_exit` cleanup
- Follow `describe "function/arity"` → `test "specific case"` structure

### Git Workflow

**Branch Naming:**
- `feature/short-description`
- `fix/issue-description`
- `docs/what-changed`

### CI/CD

**CI** (`.github/workflows/ci.yml`) — Runs on push/PR to `main`:
1. Setup Rust 1.95.0, Elixir 1.19.5/OTP 28
2. Cache deps and `_build`
3. `mix compile --warnings-as-errors`
4. `mix format --check-formatted`
5. `mix credo --strict`
6. `mix test`

**Release** (`.github/workflows/release.yml`) — Runs on `v*` tags:
1. Setup Rust + Elixir/OTP
2. `mix hex.publish --yes` (requires `HEX_API_KEY` secret)

### URL Conventions

| Content Type | URL Pattern |
|--------------|-------------|
| Articles | `/articles/{slug}/` |
| Notes | `/notes/{slug}/` |
| Projects | `/projects/{slug}/` |
| Talks | `/talks/{slug}/` |
| Pages | `/{slug}/` |
| Turkish | `/tr/articles/{slug}/` |

No dates in URLs — keeps them clean and evergreen.

### Front Matter Schema

```yaml
---
title: "Required title"           # Required
date: 2024-01-15                  # Required for articles/notes/others
description: "For SEO"            # Optional
updated: 2024-01-20               # Optional
lang: en                          # Optional (default: site default)
slug: custom-slug                 # Optional (default: from filename)
categories: [cat1, cat2]          # Optional
tags: [tag1, tag2]                # Optional
draft: false                      # Optional (default: false)
featured: false                   # Optional
image: /images/cover.jpg          # Optional
layout: custom_layout             # Optional
translations:                     # Optional (auto-linked by builder)
  tr: slug-in-turkish
---
```

### Requirements

| Requirement | Version | Source |
|-------------|---------|--------|
| Elixir | 1.19.5 | `mise.toml` |
| OTP | 28 | CI / `mise.toml` |
| Rust | 1.95.0 (stable) | CI — required for MDEx NIF |

### Dependencies

```elixir
# Core
{:mdex, "~> 0.12"},                                     # Markdown (Rust NIF)
{:yaml_elixir, "~> 2.12"},                              # YAML front matter
{:slugify, "~> 1.3"},                                   # URL slugs
{:xml_builder, "~> 2.4"},                               # Atom/Sitemap XML
{:tailwind, "~> 0.4", runtime: false},                  # TailwindCSS compilation

# Optional
{:plug_cowboy, "~> 2.8", optional: true},               # Dev server
{:file_system, "~> 1.1", optional: true},               # File watching

# Dev/Test only
{:ex_doc, "~> 0.40", only: :dev, runtime: false},       # Documentation
{:credo, "~> 1.7", only: [:dev, :test], runtime: false}  # Linting
```
