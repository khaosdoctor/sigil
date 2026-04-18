import { readFileSync, existsSync } from "node:fs"
import { homedir } from "node:os"
import { join } from "node:path"

const DOMAIN_RE = /^[A-Z]{3}:/
const LEGEND_RE = /^Legend:/m

type Severity = "ok" | "warn" | "fail"
interface Finding { severity: Severity; message: string }

function memoryPath(): string {
  const encoded = process.cwd().replace(/[/.]/g, "-")
  return join(homedir(), ".claude", "projects", encoded, "memory", "MEMORY.md")
}

function check(findings: Finding[], severity: Severity, message: string) {
  findings.push({ severity, message })
}

function run() {
  const path = memoryPath()
  const findings: Finding[] = []

  if (!existsSync(path)) {
    check(findings, "fail", `MEMORY.md not found at ${path}`)
    report(path, findings)
    return
  }

  check(findings, "ok", `MEMORY.md found`)
  const raw = readFileSync(path, "utf8")
  const stripped = raw.replace(/^---[\s\S]*?---\n?/, "")
  const lines = stripped.split("\n")

  // Legend line
  if (!LEGEND_RE.test(raw)) {
    check(findings, "fail", "Missing Legend: line — ▸ will decode incorrectly")
  } else {
    check(findings, "ok", "Legend line present")
  }

  // Per-line checks
  const entryLines = lines.filter((l: string) => l.trim() && !l.startsWith("#") && !l.startsWith("Legend:") && !l.startsWith("<!--") && !l.startsWith("---"))
  const bareProse: number[] = []
  const longEntries: number[] = []
  const seenEntries: string[] = []
  const duplicates: number[] = []

  for (let i = 0; i < entryLines.length; i++) {
    const line = entryLines[i].trim()
    if (!line) continue

    if (!DOMAIN_RE.test(line)) {
      bareProse.push(i + 1)
    }

    const wordCount = line.split(/\s+/).length
    const approxTokens = Math.round(wordCount * 1.3)
    if (approxTokens > 16) longEntries.push(i + 1)

    const body = line.replace(DOMAIN_RE, "").trim()
    if (seenEntries.includes(body)) {
      duplicates.push(i + 1)
    } else {
      seenEntries.push(body)
    }
  }

  if (bareProse.length) {
    check(findings, "fail", `${bareProse.length} prose entry/entries with no domain code (lines: ${bareProse.join(", ")})`)
  }
  if (longEntries.length) {
    check(findings, "warn", `${longEntries.length} entry/entries exceed ~16 tokens — consider splitting (lines: ${longEntries.join(", ")})`)
  }
  if (duplicates.length) {
    check(findings, "warn", `${duplicates.length} possible duplicate entry/entries (lines: ${duplicates.join(", ")})`)
  }

  // TODO: compress entries
  const todoCompress = lines.filter((l: string) => l.includes("TODO: compress")).length
  if (todoCompress) {
    check(findings, "warn", `${todoCompress} entries flagged for compression (TODO: compress)`)
  }

  report(path, findings)
}

function report(path: string, findings: Finding[]) {
  const errors = findings.filter(f => f.severity === "fail").length
  const warnings = findings.filter(f => f.severity === "warn").length

  console.log(`\nSigil Doctor — ${path}`)
  console.log("─".repeat(60))

  for (const f of findings) {
    if (f.severity === "ok") continue
    const icon = f.severity === "fail" ? "✗" : "⚠"
    console.log(`${icon} ${f.message}`)
  }

  const okCount = findings.filter(f => f.severity === "ok").length
  if (okCount === findings.length) {
    console.log("✓ All checks passed")
  }

  console.log(`\nFindings: ${errors} error(s), ${warnings} warning(s)`)

  process.exit(errors > 0 ? 1 : 0)
}

run()
