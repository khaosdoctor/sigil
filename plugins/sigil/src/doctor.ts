import { readFileSync, existsSync } from "node:fs"
import { homedir } from "node:os"
import { join } from "node:path"

const DOMAIN_RE = /^[A-Z]{3}:/
const LEGEND_RE = /^Legend:/m

type Severity = "ok" | "warn" | "fail"
interface Finding { severity: Severity; message: string }

function memoryPaths(): string[] {
  const slug = process.cwd().replace(/[/.]/g, "-")
  return [
    join(homedir(), ".claude", "projects", slug, "memory", "MEMORY.md"),
    join(process.cwd(), ".claude", "memory", "MEMORY.md"),
    join(homedir(), ".claude", "memory", "MEMORY.md"),
  ]
}

function check(findings: Finding[], severity: Severity, message: string) {
  findings.push({ severity, message })
}

function findStalePaths(line: string): string[] {
  const stale: string[] = []
  for (const m of line.matchAll(/@\(([~\/][^)]+)\)/g)) {
    let p = m[1]
    if (p.startsWith("~")) p = join(homedir(), p.slice(2))
    if (!existsSync(p)) stale.push(p)
  }
  return stale
}

function checkFile(path: string): { findings: Finding[]; exists: boolean } {
  const findings: Finding[] = []

  if (!existsSync(path)) {
    return { findings, exists: false }
  }

  check(findings, "ok", "MEMORY.md found")
  const raw = readFileSync(path, "utf8")
  const stripped = raw.replace(/^---[\s\S]*?---\n?/, "")
  const lines = stripped.split("\n")

  if (!LEGEND_RE.test(raw)) {
    check(findings, "fail", "Missing Legend: line — ▸ will decode incorrectly")
  } else {
    check(findings, "ok", "Legend line present")
  }

  const entryLines = lines.filter(
    (l) =>
      l.trim() &&
      !l.startsWith("#") &&
      !l.startsWith("Legend:") &&
      !l.startsWith("<!--") &&
      !l.startsWith("---"),
  )

  const bareProse: number[] = []
  const longEntries: number[] = []
  const seenEntries: string[] = []
  const duplicates: number[] = []
  const staleRefs: Array<{ line: number; path: string }> = []

  for (let i = 0; i < entryLines.length; i++) {
    const line = entryLines[i].trim()
    if (!line) continue

    if (!DOMAIN_RE.test(line)) {
      bareProse.push(i + 1)
      continue
    }

    const wordCount = line.split(/\s+/).length
    if (Math.round(wordCount * 1.3) > 16) longEntries.push(i + 1)

    const body = line.replace(DOMAIN_RE, "").trim()
    if (seenEntries.includes(body)) {
      duplicates.push(i + 1)
    } else {
      seenEntries.push(body)
    }

    for (const p of findStalePaths(line)) {
      staleRefs.push({ line: i + 1, path: p })
    }
  }

  if (bareProse.length) {
    check(findings, "fail", `${bareProse.length} prose entry/entries with no domain code (lines: ${bareProse.join(", ")})`)
  }
  if (longEntries.length) {
    check(findings, "warn", `${longEntries.length} entry/entries exceed ~16 tokens (lines: ${longEntries.join(", ")})`)
  }
  if (duplicates.length) {
    check(findings, "warn", `${duplicates.length} possible duplicate(s) (lines: ${duplicates.join(", ")})`)
  }
  for (const { line, path } of staleRefs) {
    check(findings, "warn", `Line ${line}: path no longer exists — ${path}`)
  }

  const todoCompress = lines.filter((l) => l.includes("TODO: compress")).length
  if (todoCompress) {
    check(findings, "warn", `${todoCompress} entries flagged for compression (TODO: compress)`)
  }

  return { findings, exists: true }
}

function report(path: string, findings: Finding[], exists: boolean) {
  console.log(`\nSigil Doctor — ${path}`)
  console.log("─".repeat(60))

  if (!exists) {
    console.log("  (not found — skipping)")
    return
  }

  const issues = findings.filter((f) => f.severity !== "ok")
  if (issues.length === 0) {
    console.log("✓ All checks passed")
  } else {
    for (const f of issues) {
      const icon = f.severity === "fail" ? "✗" : "⚠"
      console.log(`${icon} ${f.message}`)
    }
  }
}

function run() {
  const paths = memoryPaths()
  let totalErrors = 0
  let totalWarnings = 0

  for (const path of paths) {
    const { findings, exists } = checkFile(path)
    report(path, findings, exists)
    totalErrors += findings.filter((f) => f.severity === "fail").length
    totalWarnings += findings.filter((f) => f.severity === "warn").length
  }

  console.log(`\nTotal: ${totalErrors} error(s), ${totalWarnings} warning(s) across ${paths.length} location(s)`)
  process.exit(totalErrors > 0 ? 1 : 0)
}

run()
