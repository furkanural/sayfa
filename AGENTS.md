# AGENTS.md

Guidance for coding agents working in the Sayfa repository.

## Project Snapshot

- Project: **Sayfa** - an Elixir static site generator.
- Package role: reusable Hex package (not a single website app).
- Architecture: core library here + user sites consuming it.
- Main language: Elixir (`.ex`, `.exs`) with EEx templates and some JS/CSS assets.

## Runtime and Toolchain

- Elixir: `1.19.5` (compatible `~> 1.19` in `mix.exs`).
- OTP: `28`.
- Rust: `1.93.0` stable (required by `mdex` NIF dependency).
- Common setup command: `mix deps.get`.

## Build, Lint, and Test Commands

Run from repository root.

### Core commands

- Compile: `mix compile`
- Compile with strict warnings: `mix compile --warnings-as-errors`
- Format code: `mix format`
- Check formatting only: `mix format --check-formatted`
- Lint (Credo strict): `mix credo --strict`
- Run all tests: `mix test`
- Run tests with coverage: `mix test --cover`
- Build docs: `mix docs`

### Run a single test (important)

- One test file: `mix test test/sayfa/content_test.exs`
- One exact line in a file: `mix test test/sayfa/content_test.exs:110`
- Re-run only failed tests: `mix test --failed`

### Full CI-equivalent local check

Run these in order before opening a PR or committing non-trivial changes:

1. `mix compile --warnings-as-errors`
2. `mix format --check-formatted`
3. `mix credo --strict`
4. `mix test`

This mirrors `.github/workflows/ci.yml`.

## Development Commands

- Start dev server with watch/rebuild: `mix sayfa.serve`
- Clean/build via API or mix tasks as needed for feature validation.

## Repository Layout (high-value paths)

- Public API: `lib/sayfa.ex`
- Core pipeline: `lib/sayfa/builder.ex`
- Content parsing/domain model: `lib/sayfa/content.ex`, `lib/sayfa/content/raw.ex`
- Behaviours: `lib/sayfa/behaviours/`
- Built-in blocks: `lib/sayfa/blocks/`
- Content types: `lib/sayfa/content_types/`
- Dev server: `lib/sayfa/dev_server/`
- Mix tasks: `lib/mix/tasks/`
- Default theme/templates/assets: `priv/default_theme/`
- Translations: `priv/translations/`
- Tests: `test/`

## Code Style and Conventions

Follow existing project style from `CLAUDE.md`, code samples, and formatter defaults.

### Formatting

- Use `mix format` for all Elixir files.
- Formatter inputs include: `{mix,.formatter}.exs` and `{config,lib,test}/**/*.{ex,exs}`.
- Never manually "pretty format" against formatter output.

### Module and file naming

- Main modules: `Sayfa.ModuleName`
- Behaviours: `Sayfa.Behaviours.BehaviourName`
- Blocks: `Sayfa.Blocks.BlockName`
- Content types: `Sayfa.ContentTypes.TypeName`
- Dev server modules: `Sayfa.DevServer.ModuleName`
- Mix tasks: `Mix.Tasks.Sayfa.TaskName`

### Function naming

- Use snake_case, usually `verb_noun` style.
- Boolean predicates end with `?` (example: `draft?`).
- Raising variants end with `!` (example: `parse!`, `build!`).

### Imports, aliases, and requires

- Prefer `alias` at module top for frequently used project modules.
- Use `require Logger` when macros are needed (as in `builder.ex`).
- Avoid broad `import`; keep function calls explicit unless local style already uses imports.
- Keep alias list readable and stable; do not reorder purely for churn.

### Types, docs, and structs

- Public modules should include `@moduledoc`.
- Public functions should include `@doc` and examples where practical.
- Add `@spec` for public functions.
- For structs:
  - Use `@enforce_keys` for required fields.
  - Define `@type t :: %__MODULE__{...}`.
  - Use `defstruct` defaults for optional fields.

### Error handling

- Prefer tagged tuple returns: `{:ok, value}` / `{:error, reason}`.
- Provide `!` versions for convenience when appropriate.
- Use descriptive reason atoms/tuples (example patterns: `:missing_title`, `{:parse_error, file, reason}`).
- Reserve exceptions for truly exceptional or explicit raising APIs.

### Path and file handling

- Use `Path.join/2` for path composition.
- Be careful with recursive copy/delete operations; match existing Builder patterns.
- Keep cross-platform behavior in mind (even though CI runs on Ubuntu).

## Testing Guidelines

- Use `ExUnit.Case, async: true` for isolated unit tests when safe.
- Prefer `describe "function/arity"` blocks and specific test names.
- Use temporary directories and `on_exit` cleanup for filesystem tests.
- Add regression tests for every bug fix.
- For parser/content pipeline changes, test both success and error tuple paths.

## Domain-Specific Implementation Notes

- Respect content pipeline stages: load -> parse -> transform -> render -> write.
- Keep the Raw -> Content two-struct boundary clear.
- Do not break block behaviour contracts (`name/0`, `render/1`).
- Do not break hook stage contracts (`:before_parse`, `:after_parse`, `:before_render`, `:after_render`).
- Preserve i18n behavior, including hreflang enrichment and RTL direction support.
- Keep URL conventions stable (no date segments in generated content URLs).

## JavaScript Asset Rule (important)

When editing `priv/default_theme/assets/js/enhancements.js`:

- Manually update `priv/default_theme/assets/js/enhancements.min.js`.
- Keep section comments (e.g. `/* 1. Reading progress bar */`).
- Remove other comments/whitespace and shorten local variable names.
- Keep behavior exactly equivalent.

## Git and PR Conventions

- Branch names: `feature/...`, `fix/...`, `docs/...`.
- Commit messages: conventional commits (`feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `style:`, `chore:`).
- Avoid unrelated refactors in focused changes.

## Agent-Specific Safety Checklist

- Read neighboring modules before changing public contracts.
- Keep edits minimal and consistent with existing architecture.
- Run targeted tests first, then broader suite.
- Before finalizing significant changes, run the full CI-equivalent commands.

## Cursor/Copilot Rules

- `.cursorrules`: not found at repository root.
- `.cursor/rules/`: not found.
- `.github/copilot-instructions.md`: not found.
- If these files are added later, treat them as higher-priority agent instructions and update this document.
