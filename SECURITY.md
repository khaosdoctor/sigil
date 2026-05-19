# Security & How Sigil Works

This document exists so you can install Sigil with eyes open. It explains
exactly what the plugin runs, what it reads, what it writes, and what it
does **not** do.

Sigil is small enough to audit in one sitting. If anything here surprises
you, the source files are linked so you can verify each claim yourself.

---

## TL;DR

- **No network.** Sigil never opens a socket, makes an HTTP request, or
  contacts a remote server. There is no telemetry, no analytics, no
  "phone home." Every operation is local-only.
- **No execution of untrusted code.** Sigil never `eval`s, `source`s, or
  spawns code from `MEMORY.md` content. Memory files are treated as text.
- **Reads only from known locations.** The plugin reads memory files
  from three fixed scopes (project / local / global) and one optional
  statusline file. Paths are listed below.
- **Writes are scoped and backed up.** The only files Sigil writes are
  your own `MEMORY.md` files (when you invoke `/sigil:remember`,
  `/sigil:init`, or `/sigil:purge`) and timestamped backup copies under
  `~/.claude/backups/sigil/`. Destructive operations always back up
  first.
- **Auditable.** The full runtime surface is 7 shell scripts (< 250 lines
  total) and 2 TypeScript files (~250 lines total).

---

## What runs, and when

Sigil registers hooks with Claude Code. Each hook is a small shell
script that Claude Code invokes at a specific moment:

| Event | Script | When it fires | What it does |
|-------|--------|---------------|--------------|
| `SessionStart` | [`bin/session-start.sh`](plugins/sigil/bin/session-start.sh) | New Claude Code session | Reads your MEMORY.md files and injects them as additional context. |
| `PreToolUse` (`Write`/`Edit`) | [`bin/recall.sh`](plugins/sigil/bin/recall.sh) | Before Claude writes/edits a file | Echoes a JSON pointer to the project's MEMORY.md so Claude reads it first. |
| `Stop` | [`bin/wrap-up.sh`](plugins/sigil/bin/wrap-up.sh) | After a Claude response, when context ≥ 60% | Echoes a JSON nudge to run `/sigil:wrap-up`. |
| `Stop` | [`hooks/sigil-checkpoint.sh`](plugins/sigil/hooks/sigil-checkpoint.sh) | After a Claude response, when context ≥ 80% | Echoes a JSON reminder to save learnings. |
| `PreCompact` | [`hooks/precompact.sh`](plugins/sigil/hooks/precompact.sh) | When you run `/compact` | Tiered nudge (light / warning / blocking) based on context usage. |

All hooks:
- Read from stdin (Claude's hook payload), write JSON to stdout, and exit 0.
- Never modify files. The only file-writing happens in user-invoked
  slash commands (`/sigil:remember`, `/sigil:init`, `/sigil:purge`).
- Are gated by context-usage thresholds (where applicable) so they
  don't spam every response.

You can disable any hook by removing its entry from `plugins/sigil/hooks/hooks.json`.

---

## Slash commands and what they touch

| Command | Reads | Writes |
|---------|-------|--------|
| `/sigil:remember` | The current MEMORY.md to find the right append target | Appends a single Sigil-formatted line to MEMORY.md |
| `/sigil:init` | All three MEMORY.md scopes | Backs up to `~/.claude/backups/sigil/memories/<date>/`, then rewrites each MEMORY.md in Sigil format |
| `/sigil:doctor` | All three MEMORY.md scopes | Read-only — emits findings to stdout |
| `/sigil:purge` | All three MEMORY.md scopes | Backs up to `~/.claude/backups/sigil/purge/<date>/`, then removes duplicates / malformed entries |
| `/sigil:stats` | All three MEMORY.md scopes | Read-only — emits a stats table to stdout |
| `/sigil:encode` | Nothing | Nothing — pure transform, output to stdout |
| `/sigil:decode` | Nothing | Nothing — pure transform, output to stdout |
| `/sigil:wrap-up` | Current session context | Drafts memory entries; you confirm before any write |

Every destructive operation (`init`, `purge`) creates a timestamped
backup **before** writing.

---

## Files Sigil reads

Only these paths, derived from `$HOME` and `$PWD`:

- `$HOME/.claude/projects/-<slug>/memory/MEMORY.md` — project-scoped memory
- `$PWD/.claude/memory/MEMORY.md` — local memory (per-repo)
- `$HOME/.claude/memory/MEMORY.md` — global memory
- `/tmp/statusline-debug.json` — optional, for context-usage gating in hooks. Missing → hooks fall back to safe defaults.

The slug derivation lives in [`plugins/sigil/lib/memory-paths.sh`](plugins/sigil/lib/memory-paths.sh) and [`plugins/sigil/lib/memory-paths.ts`](plugins/sigil/lib/memory-paths.ts), so you can verify there's no path traversal: the slug is a deterministic transformation of your absolute `$PWD` (`/` and `.` become `-`).

## Files Sigil writes

Only these paths, and only on explicit slash-command invocation:

- `$HOME/.claude/projects/-<slug>/memory/MEMORY.md` (project scope)
- `$PWD/.claude/memory/MEMORY.md` (local scope)
- `$HOME/.claude/memory/MEMORY.md` (global scope)
- `$HOME/.claude/backups/sigil/{memories,purge}/<date>/...` (backups, never overwritten)

No writes outside `$HOME` or `$PWD`. No writes during hooks — hooks
only emit JSON to stdout.

---

## What Sigil does NOT do

- **No network access.** Grep the repo for `fetch`, `http`, `https`, `curl`, `wget`, `nc`, `socket` — you'll find nothing in the runtime path. The only `https://` strings are documentation links.
- **No reading of arbitrary files.** Sigil only reads the paths listed above. It does not enumerate `$HOME` or scan your filesystem.
- **No `eval` of memory content.** MEMORY.md is parsed as plain text; no part of its content is executed, sourced, or interpolated into a shell.
- **No credential access.** Sigil never reads `~/.ssh`, `~/.aws`, `~/.netrc`, environment variables containing secrets, or git credentials.
- **No model invocation outside Claude Code.** The plugin uses only the slash-command and hook mechanisms Claude Code already provides.
- **No persistent background processes.** Hooks are short-lived shell invocations that exit immediately. There is no daemon, no watcher, no cron.

---

## Permissions model

Each skill declares an explicit `allowed-tools` list in its frontmatter
(see any `plugins/sigil/skills/*/SKILL.md`). Claude Code enforces these:
if a skill tries to invoke a tool outside its allow-list, the user is
prompted. Skills are intentionally narrow — e.g. `/sigil:doctor` only
allows `Bash(*)` because it invokes the TS script, while `/sigil:stats`
allows only `Bash(wc:*), Bash(find:*), Bash(cat:*)` and a few read-only
file tools.

---

## How to audit before installing

The entire runtime surface, in order of importance:

1. **Hooks (what runs automatically):** [`plugins/sigil/bin/`](plugins/sigil/bin/) and [`plugins/sigil/hooks/`](plugins/sigil/hooks/) — 5 shell scripts, ~150 lines total.
2. **Shared helpers:** [`plugins/sigil/lib/`](plugins/sigil/lib/) — 3 small shell/TS modules for context reading and memory-path derivation.
3. **Destructive commands:** [`plugins/sigil/src/doctor.ts`](plugins/sigil/src/doctor.ts) (read-only) and [`plugins/sigil/src/purge.ts`](plugins/sigil/src/purge.ts) (writes, with backups).
4. **Skills (model-driven instructions):** [`plugins/sigil/skills/`](plugins/sigil/skills/) — markdown instructions Claude follows for each slash command.
5. **Tests:** [`plugins/sigil/tests/`](plugins/sigil/tests/) — `npm test` from `plugins/sigil/` runs them.

A reasonable security review path:

```bash
# 1. Skim every hook script (none should fetch, eval, or write outside $HOME/$PWD)
ls plugins/sigil/bin plugins/sigil/hooks

# 2. Confirm no network code exists anywhere
grep -RE 'fetch|http|curl|wget|nc |socket' plugins/sigil/{bin,lib,src,hooks}

# 3. Confirm hooks don't write to disk (only emit JSON)
grep -RE 'writeFile|>>|> [^&]' plugins/sigil/{bin,hooks}

# 4. Run the test suite
cd plugins/sigil && npm install && npm test
```

---

## How to uninstall

Remove the plugin in Claude Code:

```
/plugin uninstall sigil
```

Optionally remove the marketplace entry:

```
/plugin marketplace remove khaosdoctor/sigil
```

Sigil leaves your `MEMORY.md` files in place — they're yours. To
remove them too:

```bash
rm -rf ~/.claude/memory ~/.claude/projects/*/memory ~/.claude/backups/sigil
```

(Skip the last path if you want to keep the backups.)

---

## Reporting a vulnerability

If you find a security issue, please open a private security advisory on
GitHub rather than a public issue:
<https://github.com/khaosdoctor/sigil/security/advisories>

Or contact the author via the email listed on their GitHub profile.
