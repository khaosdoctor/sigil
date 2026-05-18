import { readFileSync, writeFileSync, existsSync } from "node:fs"
import { homedir } from "node:os"
import { join } from "node:path"

const DOMAIN_RE = /^[A-Z]{3}:/
const LEGEND_RE = /^Legend:/

const dryRun = process.argv.includes("--dry-run")

function memoryPath(): string {
  const encoded = process.cwd().replace(/[/.]/g, "-")
  return join(homedir(), ".claude", "projects", encoded, "memory", "MEMORY.md")
}

function run() {
  const path = memoryPath()

  if (!existsSync(path)) {
    console.error(`No MEMORY.md found at ${path}`)
    process.exit(1)
  }

  const raw = readFileSync(path, "utf8")
  const frontmatterMatch = raw.match(/^(---[\s\S]*?---\n?)/)
  const frontmatter = frontmatterMatch?.[0] ?? ""
  const body = raw.slice(frontmatter.length)
  const lines = body.split("\n")

  const seenEntries: string[] = []
  const removed: string[] = []
  const kept: string[] = []

  for (const line of lines) {
    const trimmed = line.trim()

    // Always keep structural lines
    if (!trimmed || trimmed.startsWith("#") || LEGEND_RE.test(trimmed) || trimmed.startsWith("<!--")) {
      kept.push(line)
      continue
    }

    // Remove prose entries with no domain code
    if (!DOMAIN_RE.test(trimmed)) {
      removed.push(`[no domain code] ${line}`)
      continue
    }

    // Remove duplicates
    const body = trimmed.replace(DOMAIN_RE, "").trim()
    if (seenEntries.includes(body)) {
      removed.push(`[duplicate] ${line}`)
      continue
    }

    seenEntries.push(body)
    kept.push(line)
  }

  console.log(`\nSigil Purge${dryRun ? " (dry run)" : ""} — ${path}`)
  console.log("─".repeat(60))

  if (removed.length === 0) {
    console.log("Nothing to purge.")
    process.exit(0)
  }

  for (const r of removed) {
    console.log(`✗ ${r}`)
  }

  console.log(`\n${removed.length} entry/entries to remove.`)

  if (dryRun) {
    console.log("Run without --dry-run to apply.")
    process.exit(0)
  }

  writeFileSync(path, frontmatter + kept.join("\n"), "utf8")
  console.log("Done.")
}

run()
