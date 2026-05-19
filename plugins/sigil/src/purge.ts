import { readFileSync, writeFileSync, existsSync, mkdirSync, copyFileSync } from "node:fs"
import { homedir } from "node:os"
import { join } from "node:path"
import { fileURLToPath } from "node:url"

const DOMAIN_RE = /^[A-Z]{3}:/
const LEGEND_RE = /^Legend:/

const dryRun = process.argv.includes("--dry-run")

export function splitFrontmatter(raw: string): { frontmatter: string; body: string } {
  const m = raw.match(/^(---[\s\S]*?---\n?)/)
  const frontmatter = m?.[0] ?? ""
  return { frontmatter, body: raw.slice(frontmatter.length) }
}

// The heart of purge — pure. Mirrors the EXACT current loop in purgeFile.
export function purgeLines(lines: string[]): { kept: string[]; removed: string[] } {
  const seenEntries: string[] = []
  const removed: string[] = []
  const kept: string[] = []
  for (const line of lines) {
    const trimmed = line.trim()
    if (!trimmed || trimmed.startsWith("#") || LEGEND_RE.test(trimmed) || trimmed.startsWith("<!--")) { kept.push(line); continue }
    if (!DOMAIN_RE.test(trimmed)) { removed.push(`[no domain code] ${line}`); continue }
    const entryBody = trimmed.replace(DOMAIN_RE, "").trim()
    if (seenEntries.includes(entryBody)) { removed.push(`[duplicate] ${line}`); continue }
    seenEntries.push(entryBody)
    kept.push(line)
  }
  return { kept, removed }
}

function memoryPaths(): string[] {
  // leading / becomes - matching Claude's path-slug convention (equivalent to shell: sed 's|^/||; s|[/.]|-|g' then prepend -)
  const slug = process.cwd().replace(/[/.]/g, "-")
  return [
    join(homedir(), ".claude", "projects", slug, "memory", "MEMORY.md"),
    join(process.cwd(), ".claude", "memory", "MEMORY.md"),
    join(homedir(), ".claude", "memory", "MEMORY.md"),
  ].filter(existsSync)
}

function backup(path: string): void {
  const date = new Date().toISOString().slice(0, 10)
  const dir = join(homedir(), ".claude", "backups", "sigil", "purge", date)
  mkdirSync(dir, { recursive: true })
  const encoded = path.replace(/[/.]/g, "-").replace(/^-+/, "")
  const dest = join(dir, encoded)
  copyFileSync(path, dest)
  console.log(`  Backup saved to ${dest}`)
}

function purgeFile(path: string): void {
  console.log(`\nSigil Purge${dryRun ? " (dry run)" : ""} — ${path}`)
  console.log("─".repeat(60))

  const raw = readFileSync(path, "utf8")
  const { frontmatter, body } = splitFrontmatter(raw)
  const lines = body.split("\n")

  const { kept, removed } = purgeLines(lines)

  if (removed.length === 0) {
    console.log("Nothing to purge.")
    return
  }

  for (const r of removed) console.log(`✗ ${r}`)
  console.log(`\n${removed.length} entry/entries to remove.`)

  if (dryRun) {
    console.log("Run without --dry-run to apply.")
    return
  }

  backup(path)
  writeFileSync(path, frontmatter + kept.join("\n"), "utf8")
  console.log("Done.")
}

function run() {
  const paths = memoryPaths()
  if (paths.length === 0) {
    console.error("No MEMORY.md files found.")
    process.exit(1)
  }
  for (const path of paths) purgeFile(path)
}

if (process.argv[1] === fileURLToPath(import.meta.url)) run()
