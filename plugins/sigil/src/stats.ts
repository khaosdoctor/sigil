// /sigil:stats implementation. Reads every MEMORY.md returned by
// memoryLocations() and prints one summary block per location plus a totals
// line when more than one exists. Read-only — no writes, no network.
//
// Token math:
//   tokens ≈ word_count × 1.3   — matches the BPE estimate used elsewhere
//   prose  ≈ tokens × 4         — conservative lower bound from
//     token-compression-experiment.md (empirical range is 4–50×, so this
//     understates savings rather than overstates them).
//
// Wired up via `skills/stats/SKILL.md` which does nothing but invoke this
// script through tsx; see docs/COMMAND_FLOWS.md.

import { readFileSync, existsSync } from "node:fs"
import { fileURLToPath } from "node:url"
import { memoryLocations } from "../lib/memory-paths.ts"

const DOMAIN_RE = /^[A-Z]{3}:/        // full entry: "GIT: commit-single"
const DOMAIN_HEAD_RE = /^[A-Z]{3}/    // just the 3-letter prefix, for grouping

function estimateTokens(text: string): number {
  const words = text.trim().split(/\s+/).filter(Boolean).length
  return Math.round((words * 13) / 10)
}

interface FileStats {
  path: string
  entries: number
  tokens: number
  prose: number
  domains: Array<[string, number]>
}

function statsFor(path: string): FileStats | null {
  if (!existsSync(path)) return null
  const raw = readFileSync(path, "utf8")
  const lines = raw.split("\n")
  const entries = lines.filter((l) => DOMAIN_RE.test(l.trim())).length
  const tokens = estimateTokens(raw)
  const prose = tokens * 4

  const counts = new Map<string, number>()
  for (const l of lines) {
    const m = l.trim().match(DOMAIN_HEAD_RE)
    if (m && DOMAIN_RE.test(l.trim())) counts.set(m[0], (counts.get(m[0]) ?? 0) + 1)
  }
  const domains = [...counts.entries()].sort((a, b) => b[1] - a[1])

  return { path, entries, tokens, prose, domains }
}

function ratio(tokens: number, prose: number): string {
  if (tokens === 0) return "—"
  return `${(prose / tokens).toFixed(1)}x`
}

function run() {
  const results = memoryLocations()
    .map((l) => statsFor(l.path))
    .filter((s): s is FileStats => s !== null)

  if (results.length === 0) {
    console.log("No Sigil memory files found.")
    console.log("Run /sigil:remember to save your first memory, or /sigil:init to migrate existing ones.")
    return
  }

  let totalEntries = 0
  let totalTokens = 0

  for (const s of results) {
    totalEntries += s.entries
    totalTokens += s.tokens
    console.log(`Location: ${s.path}`)
    console.log(`Entries: ${s.entries} | Tokens: ~${s.tokens} compressed -> ~${s.prose} prose (${ratio(s.tokens, s.prose)})`)
    if (s.domains.length) {
      const summary = s.domains.map(([d, n]) => `${d}:${n}`).join(" ")
      console.log(`Domains: ${summary}`)
    }
    console.log()
  }

  if (results.length > 1) {
    console.log("----------------------------------------------------------")
    console.log(
      `Total: ${results.length} location(s) | ${totalEntries} entries | ~${totalTokens} tokens compressed -> ~${totalTokens * 4} as prose`,
    )
  }
}

if (process.argv[1] === fileURLToPath(import.meta.url)) run()
