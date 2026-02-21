# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.1] - 2026-02-11

### Fixed

- Guard DevServer modules behind compile-time checks so the package works without optional dependencies installed
- Ensure application startup in Mix tasks (`sayfa.build`, `sayfa.serve`)

## [0.1.0] - 2025-02-11

Initial release of Sayfa — a static site generator built in Elixir.

### Added

#### Core
- Markdown parsing via MDEx (Rust NIF) with syntax highlighting
- YAML front matter extraction with known fields + `meta` catch-all map
- Two-struct content pipeline (`Content.Raw` -> `Content`)
- Slug generation from filenames with date prefix stripping
- Collections API: filter by type/tag/category, sort by date, group, recent

#### Build Pipeline
- Full build orchestration (`Sayfa.Builder`)
- Three-layer template composition (content body -> layout -> base)
- EEx template rendering with `@block` helper injection
- Configuration system with defaults, app env, and runtime overrides
- Static asset copying
- Draft filtering

#### Content Types
- 5 built-in content types: Post, Note, Project, Talk, Page
- Content type behaviour for custom types (`Sayfa.Behaviours.ContentType`)
- Layout selection: front matter -> content type default -> fallback
- Category and tag archive page generation
- Pagination with configurable posts per page

#### Feeds & SEO
- Atom feed generation
- Sitemap XML generation
- Pagefind search integration (post-build indexing)
- SEO meta tags (Open Graph, description)
- Reading time calculation
- Table of contents extraction from headings

#### Blocks
- Block behaviour and registry system (`Sayfa.Behaviours.Block`)
- `@block.(:name, opts)` helper available in all templates
- 9 built-in blocks: hero, header, footer, social_links, toc, recent_posts, tag_cloud, reading_time, code_copy

#### Extensibility
- Hook behaviour with 4 pipeline stages: before_parse, after_parse, before_render, after_render
- Theme system with inheritance (custom theme -> parent -> default)
- Multilingual support (directory-based i18n)

#### Developer Experience
- `mix sayfa.new` — project generator with sample content
- `mix sayfa.build` — build with `--source`, `--output`, `--drafts`, `--verbose` flags
- `mix sayfa.serve` — dev server with file watching and hot reload
- Build caching for incremental rebuilds
- Verbose logging with per-stage timing

[0.1.1]: https://github.com/furkanural/sayfa/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/furkanural/sayfa/releases/tag/v0.1.0
