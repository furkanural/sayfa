# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.4.2] - 2026-03-06

### Breaking Changes

- **`hero` block removed**: `Sayfa.Blocks.Hero` has been removed from the built-in block registry. The default home layout no longer renders a hero section — site title and description are already visible in the header, so the hero was redundant. Users who relied on `@block.(:hero, ...)` in custom layouts should replace it with content from their `index.md` body or a custom block. The `.home-hero-section` and `.hero-subtitle` CSS classes are also removed from the default theme.

## [0.4.1] - 2026-03-06

### Fixed

- **Hot reload CSS loss**: Asset fingerprinting is now skipped during `mix sayfa.serve`. Every hot reload previously accumulated old fingerprinted files in `dist/assets/` (e.g. `main.abc.abc.css`), causing the browser to request a URL that no longer existed after the next rename. Dev mode uses `location.reload()` for cache freshness so fingerprinting is unnecessary there.
- **Fingerprinted file accumulation on repeated `mix sayfa.build` runs**: `digest_assets` now reads the previous `manifest.json` and deletes all previously fingerprinted files before rescanning `dist/assets/`. This prevents old `*.hash.css` / `*.hash.js` files from accumulating across repeated production builds.

### Added

- **`:fingerprint` build option**: Pass `fingerprint: false` to `Sayfa.Builder.build/1` to skip asset digesting (e.g. for custom dev tooling). Defaults to `true` so `mix sayfa.build` behaviour is unchanged.

## [0.4.0] - 2026-03-06

### Breaking Changes

- **`Post` content type renamed to `Article`**: `Sayfa.ContentTypes.Post` is now `Sayfa.ContentTypes.Article`. Content files in `posts/` directories should move to `articles/`, URLs change from `/posts/{slug}/` to `/articles/{slug}/`, and the `layout: "post"` front matter key should be updated to `layout: "article"`. The `recent_posts` and `related_posts` blocks are renamed to `recent_articles` and `related_articles` respectively.

### Added

- **Asset digesting**: The builder now computes content hashes for compiled CSS and JS files and rewrites references in the base layout to cache-busted URLs (e.g. `app-a1b2c3d4.css`), enabling long-lived caching in production.
- **Language switcher `variant:` assign**: Render multiple language switcher instances on the same page with unique element IDs by passing `variant: :desktop` or `variant: :mobile`. The generated element ID becomes `lang-switcher-desktop` / `lang-switcher-mobile` instead of the default `lang-switcher`.
- **Language switcher home fallback**: The language switcher no longer hides when a page has no verified translation — it falls back to the target language's home path (`/` or `/lang/`) so the switcher is always visible.
- **`AGENTS.md`**: Guidance file for AI coding agents working on the Sayfa codebase.

### Changed

- **Default theme rewritten with Catppuccin Latte/Mocha palette**: The entire default theme CSS has been rewritten using the [Catppuccin](https://github.com/catppuccin/catppuccin) color system. Latte (light) and Mocha (dark) palettes auto-switch via `prefers-color-scheme`. All palette tokens are registered as `--color-ctp-*` Tailwind utilities via `@theme inline`. Feed tooltip contrast meets WCAG AA in both modes.
- **Semantic CSS component classes**: All block modules now emit semantic component class names (e.g. `.header-shell`, `.content-card`, `.toc-nav`) instead of raw Tailwind utilities. Styles are centralized in `main.css` and reference `--color-ctp-*` / `--site-*` CSS variables for theming.
- **Breadcrumb block redesigned as a back-link**: The full `<nav>` breadcrumb trail is replaced with a minimal `← Section` back link for section content. Bare pages (no `url_prefix`) emit only the JSON-LD `BreadcrumbList` structured data without a visible link. List and home pages produce no output.
- **Arabic font loading stabilized**: `@font-face` declarations for Arabic fonts now load reliably across builds.

## [0.3.3] - 2026-02-28

### Added

- **Dedicated project and talk layouts**: Projects and talks now render with full-featured layouts (`project.html.eex`, `talk.html.eex`) instead of the bare page layout — displaying date, updated date, categories and tags as clickable archive links, copy link button, reading time, table of contents, cover image, and related content. The talk layout additionally surfaces `event`, `video`, and `slides` front matter fields with dedicated UI.
- **Feed subscription links on list pages**: Type index pages, tag archives, and category archives now display inline Atom/JSON feed links below the heading, with tooltip labels. Corresponding `<link rel="alternate">` tags are also emitted in `<head>`.
- **JSON feeds for tag and category archives**: `Feed.generate_json_for_tag/3` and `Feed.generate_json_for_category/3` added; the builder now writes `.json` feed files alongside the existing `.xml` files for every tag and category archive.
- **`subscribe_via_atom` and `subscribe_via_json` translation keys**: Added to all 14 built-in language files (en, tr, de, es, fr, it, pt, ja, ko, zh, ar, ru, nl, pl).
- **Footer feed links**: The footer block now renders inline Atom and JSON feed subscription links next to the copyright line.

### Changed

- **Project default layout**: `Sayfa.ContentTypes.Project` now uses `"project"` as its default layout (was `"page"`).
- **Talk default layout**: `Sayfa.ContentTypes.Talk` now uses `"talk"` as its default layout (was `"page"`).
- **Per-language feeds removed**: The builder no longer generates separate `/tr/feed.xml` (and similar) files per language — the root `/feed.xml` already includes all languages.
- **`DateFormat.format/3`**: Now accepts `nil` (returns `""`), `DateTime`, `NaiveDateTime`, and ISO 8601 strings in addition to `Date` structs.
- **Scaffold templates**: `mix sayfa.new` project and talk example files updated — projects gain a `date:` field; talks rename `slides_url:` to `slides:` to match the new layout.

## [0.3.2] - 2026-02-28

### Fixed

- **Mobile code block overflow**: Code blocks no longer cause horizontal page scroll on mobile — `max-width: 100%` is now applied to `pre` elements inside `.prose-content`, and `max-w-full` added to the JS-enhanced code copy wrapper

## [0.3.1] - 2026-02-27

### Changed

- **Elixir requirement**: Updated minimum Elixir version from `~> 1.18` to `~> 1.19`
- **Dependency updates**: Updated core dependencies to latest stable versions — mdex `~> 0.11`, yaml_elixir `~> 2.12`, xml_builder `~> 2.4`, plug_cowboy `~> 2.8`, file_system `~> 1.1`, ex_doc `~> 0.40`

### Fixed

- **`mix sayfa.new` version constraint**: New sites were scaffolded with `{:sayfa, "~> 0.1"}` — now correctly uses `"~> 0.3"`
- **ExDoc module groups**: Added 8 missing blocks to the docs module groups — `CategoryCloud`, `RecentContent`, `CopyLink`, `Breadcrumb`, `LanguageSwitcher`, `RelatedPosts`, `RelatedContent`, `Analytics`

## [0.3.0] - 2026-02-27

### Added

- **Logo support in header**: Set `logo: "/images/logo.svg"` in site config to replace the plain text title with an image in the header block. Optionally set `logo_dark:` for a separate dark-mode variant — the light logo gains `dark:hidden` and the dark logo `hidden dark:block` Tailwind classes automatically. Falls back to text title when neither key is present.
- **Print styles**: Built-in CSS print styles for clean printed pages
- **View transitions**: Smooth page transitions using the View Transitions API
- **Highlight theme**: Configurable syntax highlighting theme support
- **`related_content` block**: Show related content across different content types
- **`analytics` block**: Built-in analytics integration block
- **Responsive images hook**: Automatic `srcset` generation for responsive images
- **`mix sayfa.gen.images` task**: Image optimization pipeline scaffold (vips/ImageMagick)
- **Content validation**: Validates required front matter fields during build and reports errors
- **Prev/next navigation**: Automatic previous/next content links generated by the builder
- **`mix sayfa.gen.lang` task**: Add language support to an existing site
- **Multilingual content generation**: `mix sayfa.new` now generates content files for non-default languages

### Changed

- **Output directory renamed**: Default build output directory changed from `output` to `dist`
- **Nixpacks**: Replaced Docker with Nixpacks configuration in the new site template

### Fixed

- **Image optimization script**: Removed unsupported `--format` flag from `vips thumbnail` calls (format is inferred from file extension)
- **Image optimization script**: Prevent duplicate processing — skip `*_1200.*` files and already-optimized sources on reruns

## [0.2.0] - 2026-02-23

### Added

- **Internationalization**: Translation system with 14 built-in languages (English, Turkish, German, Spanish, French, Italian, Portuguese, Japanese, Korean, Chinese, Arabic, Russian, Dutch, Polish)
- **New Blocks**: Language switcher, category cloud, related posts, breadcrumb, copy link
- **Image Helper**: Responsive image module with srcset, lazy loading, and WebP support
- **Excerpt Extraction**: Automatic content summaries for list pages and feeds
- **Reading Progress**: Visual progress bar and ToC scroll-spy for long articles
- **Mix Tasks**: `mix sayfa.gen.content` and `mix sayfa.gen.layout` generators
- **SEO Enhancements**: JSON-LD structured data, hreflang tags for multilingual content
- **Multilingual Archives**: Tag and category archive pages with language support
- **Self-Hosted Fonts**: Eliminate Google Fonts dependency for better privacy
- **Deployment Support**: Nixpacks config and GitHub Pages workflow
- **Component Classes**: Reusable Tailwind utilities for consistent styling
- **Expanded Social Icons**: Support for 24 social media platforms

### Fixed

- Language switcher mobile functionality with unique IDs for desktop/mobile variants
- Localized home URL detection in header active state
- Translated reading time labels across all languages
- TailwindCSS typography plugin for proper prose styling
- URL generation with correct trailing slash handling

### Changed

- Redesigned default theme layouts with Tailwind utilities
- Simplified block implementations to use component classes
- DevServer dependencies now required (no longer optional)

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

[0.4.2]: https://github.com/furkanural/sayfa/compare/v0.4.1...v0.4.2
[0.4.1]: https://github.com/furkanural/sayfa/compare/v0.4.0...v0.4.1
[0.4.0]: https://github.com/furkanural/sayfa/compare/v0.3.3...v0.4.0
[0.3.3]: https://github.com/furkanural/sayfa/compare/v0.3.2...v0.3.3
[0.3.2]: https://github.com/furkanural/sayfa/compare/v0.3.1...v0.3.2
[0.3.1]: https://github.com/furkanural/sayfa/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/furkanural/sayfa/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/furkanural/sayfa/compare/v0.1.1...v0.2.0
[0.1.1]: https://github.com/furkanural/sayfa/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/furkanural/sayfa/releases/tag/v0.1.0
