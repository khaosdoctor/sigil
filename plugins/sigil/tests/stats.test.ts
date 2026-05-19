import { test } from "node:test"
import assert from "node:assert/strict"
import { execFileSync, type ExecFileSyncOptions } from "node:child_process"
import { mkdtempSync, mkdirSync, writeFileSync, rmSync, realpathSync } from "node:fs"
import { createRequire } from "node:module"
import { tmpdir } from "node:os"
import { dirname, join, resolve } from "node:path"
import { fileURLToPath, pathToFileURL } from "node:url"

const __filename = fileURLToPath(import.meta.url)
const __dirname = dirname(__filename)
const PLUGIN_ROOT = resolve(__dirname, "..")
const STATS = join(PLUGIN_ROOT, "src", "stats.ts")
const DUMP = join(PLUGIN_ROOT, "src", "dump-memories.ts")

const require = createRequire(import.meta.url)
const TSX_LOADER_URL = pathToFileURL(require.resolve("tsx", { paths: [PLUGIN_ROOT] })).href

interface Sandbox {
  root: string
  home: string
  project: string
  cleanup: () => void
}

function makeSandbox(): Sandbox {
  const root = realpathSync(mkdtempSync(join(tmpdir(), "sigil-stats-")))
  const home = join(root, "home")
  const project = join(root, "project")
  mkdirSync(home, { recursive: true })
  mkdirSync(project, { recursive: true })
  return { root, home, project, cleanup: () => rmSync(root, { recursive: true, force: true }) }
}

function projectScopePath(home: string, projectCwd: string): string {
  const slug = projectCwd.replace(/[/.]/g, "-")
  return join(home, ".claude", "projects", slug, "memory", "MEMORY.md")
}
function localScopePath(projectCwd: string): string {
  return join(projectCwd, ".claude", "memory", "MEMORY.md")
}
function globalScopePath(home: string): string {
  return join(home, ".claude", "memory", "MEMORY.md")
}
function writeMemoryFile(path: string, content: string): void {
  mkdirSync(dirname(path), { recursive: true })
  writeFileSync(path, content, "utf8")
}

interface RunResult { status: number; stdout: string; stderr: string }
function runScript(script: string, sb: Sandbox): RunResult {
  const opts: ExecFileSyncOptions = {
    cwd: sb.project,
    env: { ...process.env, HOME: sb.home },
    encoding: "utf8",
    stdio: ["ignore", "pipe", "pipe"],
  }
  try {
    const stdout = execFileSync("node", ["--import", TSX_LOADER_URL, script], opts) as unknown as string
    return { status: 0, stdout: stdout ?? "", stderr: "" }
  } catch (err: unknown) {
    const e = err as { status?: number; stdout?: Buffer | string; stderr?: Buffer | string }
    return {
      status: typeof e.status === "number" ? e.status : 1,
      stdout: e.stdout ? e.stdout.toString() : "",
      stderr: e.stderr ? e.stderr.toString() : "",
    }
  }
}

const MEMORY_A = `Legend: ▸=prefer-over

GIT:commit-single
GIT:rebase-clean
STY:two-space-indent
TST:🚫mock-db
`

const MEMORY_B = `Legend: ▸=prefer-over

PRJ:auth-rewrite
REF:linear@INGEST
`

// ---------- stats ----------

test("stats: no MEMORY.md anywhere → friendly empty message, exit 0", () => {
  const sb = makeSandbox()
  try {
    const r = runScript(STATS, sb)
    assert.equal(r.status, 0)
    assert.match(r.stdout, /No Sigil memory files found\./)
    assert.match(r.stdout, /\/sigil:remember/)
  } finally {
    sb.cleanup()
  }
})

test("stats: single location → entry count + domain breakdown", () => {
  const sb = makeSandbox()
  try {
    const p = localScopePath(sb.project)
    writeMemoryFile(p, MEMORY_A)
    const r = runScript(STATS, sb)
    assert.equal(r.status, 0)
    assert.ok(r.stdout.includes(p), `expected path in output:\n${r.stdout}`)
    assert.match(r.stdout, /Entries: 4 \|/)
    assert.match(r.stdout, /GIT:2/)
    assert.match(r.stdout, /STY:1/)
    assert.match(r.stdout, /TST:1/)
    assert.doesNotMatch(r.stdout, /^Total:/m, "no totals line for single location")
  } finally {
    sb.cleanup()
  }
})

test("stats: multiple locations → totals line aggregates entries", () => {
  const sb = makeSandbox()
  try {
    writeMemoryFile(localScopePath(sb.project), MEMORY_A)
    writeMemoryFile(globalScopePath(sb.home), MEMORY_B)
    const r = runScript(STATS, sb)
    assert.equal(r.status, 0)
    assert.match(r.stdout, /Total: 2 location\(s\) \| 6 entries/)
  } finally {
    sb.cleanup()
  }
})

// ---------- dump-memories ----------

test("dump-memories: nothing exists → prints NO_MEMORIES", () => {
  const sb = makeSandbox()
  try {
    const r = runScript(DUMP, sb)
    assert.equal(r.status, 0)
    assert.match(r.stdout, /^NO_MEMORIES\s*$/)
  } finally {
    sb.cleanup()
  }
})

test("dump-memories: emits MEMORY header + contents for each existing scope", () => {
  const sb = makeSandbox()
  try {
    const p1 = projectScopePath(sb.home, sb.project)
    const p2 = globalScopePath(sb.home)
    writeMemoryFile(p1, MEMORY_A)
    writeMemoryFile(p2, MEMORY_B)
    const r = runScript(DUMP, sb)
    assert.equal(r.status, 0)
    assert.ok(r.stdout.includes(`===== MEMORY: ${p1} =====`))
    assert.ok(r.stdout.includes(`===== MEMORY: ${p2} =====`))
    assert.match(r.stdout, /GIT:commit-single/)
    assert.match(r.stdout, /PRJ:auth-rewrite/)
  } finally {
    sb.cleanup()
  }
})

test("dump-memories: inlines sibling .md files as LINKED sections", () => {
  const sb = makeSandbox()
  try {
    const index = localScopePath(sb.project)
    const sibling = join(dirname(index), "feedback_no_mocks.md")
    writeMemoryFile(index, MEMORY_A)
    writeFileSync(sibling, "TST:🚫mock-db,integration-only\n", "utf8")
    const r = runScript(DUMP, sb)
    assert.equal(r.status, 0)
    assert.ok(r.stdout.includes(`----- LINKED: ${sibling} -----`))
    assert.match(r.stdout, /integration-only/)
  } finally {
    sb.cleanup()
  }
})
