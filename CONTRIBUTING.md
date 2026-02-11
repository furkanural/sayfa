# Contributing to Sayfa

Thank you for your interest in contributing to Sayfa! Whether it's a bug report, feature request, documentation improvement, or code contribution, every bit helps.

## Types of Contributions

- **Bug reports** — Found something broken? [Open an issue](https://github.com/furkanural/sayfa/issues/new?template=bug_report.md).
- **Feature requests** — Have an idea? [Suggest it](https://github.com/furkanural/sayfa/issues/new?template=feature_request.md).
- **Documentation** — Typo fixes, better examples, translations.
- **Code** — Bug fixes, new features, performance improvements.

## Development Setup

### Requirements

- Elixir ~> 1.18 (OTP 27+)
- Rust (latest stable) — required for MDEx NIF compilation

### Getting Started

```bash
git clone https://github.com/furkanural/sayfa.git
cd sayfa
mix deps.get
mix test
```

Verify everything passes before making changes.

## Workflow

1. **Fork** the repository
2. **Create a branch** from `main`:
   - `feature/short-description` for new features
   - `fix/issue-description` for bug fixes
   - `docs/what-changed` for documentation
3. **Write your code** following the style conventions below
4. **Add tests** for any new functionality
5. **Run checks**:
   ```bash
   mix test
   mix format
   mix credo --strict
   ```
6. **Submit a pull request** against `main`

## Code Style

- Follow existing patterns in the codebase
- Every public module needs `@moduledoc`
- Every public function needs `@doc` with examples and `@spec`
- Use `{:ok, result}` / `{:error, reason}` tuples; provide `!` variants that raise
- Use `Path.join/2` for file paths (cross-platform compatibility)
- Refer to `CLAUDE.md` for detailed conventions

## Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add RSS feed generation
fix: handle empty front matter
docs: add block usage examples
refactor: simplify build pipeline
test: add content parser tests
chore: update dependencies
```

## Pull Request Guidelines

- Reference the related issue (e.g., "Closes #42")
- Describe what changed and why
- Add tests covering the change
- Keep PRs focused — one concern per PR
- Update `CHANGELOG.md` for user-facing changes

## Testing

```bash
mix test                              # Run all tests
mix test test/sayfa/content_test.exs  # Run a specific file
mix test --cover                      # With coverage report
```

- Write unit tests for individual modules
- Write integration tests for pipeline-level changes
- Use temporary directories for tests that write to disk

## Review Process

1. A maintainer will review your PR
2. Changes may be requested — this is normal and collaborative
3. Once approved, a maintainer will merge it

## Questions?

Open an issue or start a discussion. We're happy to help!
