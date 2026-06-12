# Changelog

All notable changes to the Sigil plugin are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.3] - 2026-06-12

### Fixed
- PreCompact hook no longer emits `hookSpecificOutput.additionalContext`, which
  is unsupported for `PreCompact` and caused every `/compact` to fail hook
  output validation. It now blocks via top-level `decision` and surfaces
  reminders via `systemMessage`.
- `read_ctx_pct` sanitizes its return to a strict numeric value before it is
  interpolated into hook JSON, preventing a malformed statusline value from
  re-breaking the hook.

## [1.2.2] - 2026-05-20

### Added
- Vercel Skills CLI installation support (`npx skills add khaosdoctor/sigil`)
- Installation instructions for Vercel Skills in README

### Changed
- `name` field added to all SKILL.md frontmatter for Vercel Skills spec compliance

## [1.2.1] - 2026-05-19

### Changed
- Version bump only — cache-buster release so the marketplace serves the
  refreshed `v1.2.0` artifacts.

## [1.2.0] - 2026-05-19

This is the first tagged GitHub release of the Sigil plugin. It folds together
everything previously released as `v1.1.x` plus the post-`1.1.3` work that
landed without a tag.

### Added
- **`/sigil:stats`** — new slash command that reports Sigil entry counts,
  compressed-token totals, prose-equivalent estimates, and a breakdown by
  domain code across every memory location.
- **`/sigil:encode`** — preview-only command that compresses prose into Sigil
  without touching any file, so users can try the format before saving.
- **`/sigil:decode`** — inverse of encode; expands a Sigil snippet back into
  plain prose for verification.
- **`/sigil:wrap-up`** — end-of-session capture command that scans the
  conversation for keepers and routes them through `/sigil:remember`.
- **`/sigil:doctor`** — read-only health check across all memory scopes
  (legend presence, bare-prose lines, duplicates, stale `@()` ref paths).
- **`/sigil:purge` with automatic backup** — walks project / local / global
  memory locations and writes a timestamped backup to
  `~/.claude/backups/sigil/memories/` before rewriting any file.
- **Shared path helper** — new `plugins/sigil/lib/memory-paths.ts` and
  `plugins/sigil/lib/memory-paths.sh` centralise the `projectSlug` rules and
  `MEMORY.md` location resolution previously duplicated between
  `recall.sh`, `doctor.ts`, and `purge.ts`.
- **First test suite** — `plugins/sigil/tests/` ships pure-logic and
  integration tests for `doctor`, `purge`, `stats`, `dump-memories`, and the
  shared path helper. `npm test` runs the suite via `node --import tsx --test`
  with zero new runtime dependencies.
- `docs/COMMAND_FLOWS.md` — end-to-end flow diagram for every slash command,
  showing which skill, TS script, and files each one touches.
- `plugins/sigil/src/stats.ts` and `plugins/sigil/src/dump-memories.ts`, plus
  matching `npm run stats` / `npm run dump-memories` scripts.

### Changed
- **Skills slimmed down (~51% fewer lines).** Most `SKILL.md` files now defer
  work to a TypeScript script under `plugins/sigil/src/` instead of
  orchestrating bash inline. Skill prose is shorter and unambiguous, and the
  same script runs identically whether invoked via slash command or `npm run`.
- `/sigil:stats` is now implemented in `src/stats.ts` (was inline bash in the
  skill).
- `/sigil:recall` and `/sigil:wrap-up` now load existing memory through the
  new `src/dump-memories.ts` script in one call instead of multiple `Read`s.
- `/sigil:init` delegates discovery/inventory to a `general-purpose` subagent
  so the main context never holds raw memory dumps while planning the
  migration.
- `doctor.ts` and `purge.ts` now consume `lib/memory-paths.ts` instead of
  computing slugs and paths inline.
- `recall.sh` and `session-start.sh` source `lib/memory-paths.sh` for the
  same logic in bash.

### Fixed
- **`recall.sh` slug derivation** — leading `/` and embedded `.` characters
  are now both normalised to `-`, so project-scoped `MEMORY.md` resolves to
  the same path Claude Code itself uses. Prior versions missed memories on
  paths containing dots.
- **Wrap-up nudge threshold gating** — the `Stop` wrap-up hook now respects
  the context-usage threshold from `lib/context.sh` and stays silent on
  short sessions instead of firing on every response.

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
