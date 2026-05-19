# Changelog

All notable changes to the Sigil plugin are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2026-05-19

### Added
- **`/sigil:stats`** — new slash command that reports Sigil entry counts,
  compressed-token totals, prose-equivalent estimates, and a breakdown by
  domain code across every memory location.
- **`/sigil:purge` multi-scope support with automatic backup** — purge now
  walks project / local / global memory locations and writes a timestamped
  backup to `~/.claude/backups/sigil/memories/` before rewriting any file.
- **`/sigil:doctor` multi-scope support** — doctor inspects all memory
  locations in a single pass and reports per-scope health.
- **Shared path helper** — new `plugins/sigil/lib/memory-paths.ts` and
  `plugins/sigil/lib/memory-paths.sh` centralise the `projectSlug` rules and
  `MEMORY.md` location resolution previously duplicated between
  `recall.sh`, `doctor.ts`, and `purge.ts`.
- **First test suite** — `plugins/sigil/tests/` ships pure-logic tests for
  `doctor`, `purge`, and the new path helper. `npm test` runs 19 tests via
  `node --import tsx --test` with zero new dependencies.

### Fixed
- **`recall.sh` slug derivation** — leading `/` and embedded `.` characters
  are now both normalised to `-`, so project-scoped `MEMORY.md` resolves to
  the same path Claude Code itself uses. Prior versions missed memories on
  paths containing dots.
- **Wrap-up nudge threshold gating** — the `Stop` wrap-up hook now respects
  the context-usage threshold from `lib/context.sh` and stays silent on
  short sessions instead of firing on every response.

### Changed
- `doctor.ts` and `purge.ts` now consume `lib/memory-paths.ts` instead of
  computing slugs and paths inline.
- `recall.sh` and `session-start.sh` source `lib/memory-paths.sh` for the
  same logic in bash.

## [1.1.3] - prior

### Added
- `/sigil:recall` skill for silent memory loading at session start.
- Marketplace catalogue (`.claude-plugin/marketplace.json`) so the plugin can
  be installed with `/plugin marketplace add khaosdoctor/sigil`.

### Fixed
- Memories now load directly from the `SessionStart` hook instead of relying
  on the model to invoke the recall skill.
- `recall` skill flagged as model-invocable only to avoid duplicate
  user-facing slash commands.
- README compression claim corrected to "up to 50×".

## [1.1.0] and earlier

Initial public release of the Sigil format, smart hooks
(`SessionStart`, `PreToolUse`, `PreCompact`, `Stop` checkpoint and wrap-up),
and the first slash commands (`/sigil:remember`, `/sigil:init`).

See `git log` for the full history prior to 1.1.3.
