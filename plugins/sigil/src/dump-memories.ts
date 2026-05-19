// Single-call memory dump. Used by /sigil:recall (silent context load at
// session start) and /sigil:wrap-up (dedup check before saving new entries).
//
// Why this script exists: without it, those skills would issue N Glob+Read
// calls to assemble the same picture. One tsx invocation returns the whole
// memory set as a single tool result, which keeps the model's tool-call
// surface (and token spend) flat regardless of how many memories exist.
//
// Output is a stream of fenced sections — `===== MEMORY: <path> =====` for
// each index, followed by any sibling `.md` files as `----- LINKED: ... -----`
// blocks. If nothing exists at all, prints the literal string NO_MEMORIES so
// callers can branch cheaply.

import { readFileSync, existsSync, readdirSync } from "node:fs"
import { dirname, join } from "node:path"
import { fileURLToPath } from "node:url"
import { memoryLocations } from "../lib/memory-paths.ts"

function dump() {
  let found = 0

  for (const { path } of memoryLocations()) {
    if (!existsSync(path)) continue
    found++

    console.log(`===== MEMORY: ${path} =====`)
    console.log(readFileSync(path, "utf8"))

    const dir = dirname(path)
    let siblings: string[] = []
    try {
      siblings = readdirSync(dir).filter((f) => f.endsWith(".md") && join(dir, f) !== path)
    } catch {
      siblings = []
    }
    for (const f of siblings) {
      const full = join(dir, f)
      console.log(`----- LINKED: ${full} -----`)
      console.log(readFileSync(full, "utf8"))
    }
  }

  if (found === 0) console.log("NO_MEMORIES")
}

if (process.argv[1] === fileURLToPath(import.meta.url)) dump()
