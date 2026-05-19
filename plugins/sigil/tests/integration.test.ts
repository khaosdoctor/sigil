import { test } from "node:test"
import assert from "node:assert/strict"
import { execFileSync, type ExecFileSyncOptions } from "node:child_process"
import { mkdtempSync, mkdirSync, writeFileSync, readFileSync, existsSync, rmSync, readdirSync, realpathSync } from "node:fs"
import { createRequire } from "node:module"
import { tmpdir } from "node:os"
import { dirname, join, resolve } from "node:path"
import { fileURLToPath, pathToFileURL } from "node:url"

const __filename = fileURLToPath(import.meta.url)
const __dirname = dirname(__filename)
const PLUGIN_ROOT = resolve(__dirname, "..")
const DOCTOR = join(PLUGIN_ROOT, "src", "doctor.ts")
const PURGE = join(PLUGIN_ROOT, "src", "purge.ts")

// Resolve tsx's loader as an absolute file:// URL so subprocesses can import it
// regardless of cwd (the sandbox cwd has no node_modules).
const require = createRequire(import.meta.url)
const TSX_LOADER_URL = pathToFileURL(require.resolve("tsx", { paths: [PLUGIN_ROOT] })).href

interface RunResult {
  status: number
  stdout: string
  stderr: string
}

interface Sandbox {
  root: string
  home: string
  project: string
  cleanup: () => void
}

function makeSandbox(): Sandbox {
  // Resolve symlinks (e.g. macOS /var → /private/var) so that the subprocess's
  // process.cwd() (always returned as realpath) matches the paths we compute here.
  const root = realpathSync(mkdtempSync(join(tmpdir(), "sigil-int-")))
  const home = join(root, "home")
  const project = join(root, "project")
  mkdirSync(home, { recursive: true })
  mkdirSync(project, { recursive: true })
  return {
    root,
    home,
    project,
    cleanup: () => rmSync(root, { recursive: true, force: true }),
  }
}

// Compute the project-scope MEMORY.md path the same way memory-paths.ts does.
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

function runScript(script: string, args: string[], sb: Sandbox): RunResult {
  const env = {
    ...process.env,
    HOME: sb.home,
    // Some macOS tooling honors USERPROFILE / others; HOME is what homedir() uses on POSIX.
  }
  const opts: ExecFileSyncOptions = {
    cwd: sb.project,
    env,
    encoding: "utf8",
    stdio: ["ignore", "pipe", "pipe"],
  }
  try {
    const stdout = execFileSync("node", ["--import", TSX_LOADER_URL, script, ...args], opts) as unknown as string
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

const VALID_MEMORY = `---
title: test
---
Legend: ▸=prefer-over

GIT:commit-single
STY:two-space-indent
`

const MISSING_LEGEND_MEMORY = `---
title: test
---
GIT:commit-single
STY:two-space-indent
`

const MEMORY_WITH_DUPES = `---
title: test
---
Legend: ▸=prefer-over

GIT:foo
STY:foo
TST:bar
`

// ---------- doctor ----------

test("doctor: no MEMORY.md anywhere → 'not found — skipping' 3x, exit 0", () => {
  const sb = makeSandbox()
  try {
    const r = runScript(DOCTOR, [], sb)
    const matches = r.stdout.match(/\(not found — skipping\)/g) ?? []
    assert.equal(matches.length, 3, `expected 3 'not found' notices, got ${matches.length}\nstdout:\n${r.stdout}`)
    assert.match(r.stdout, /Total: 0 error\(s\), 0 warning\(s\) across 3 location\(s\)/)
    assert.equal(r.status, 0, `expected exit 0, got ${r.status}\nstderr:\n${r.stderr}`)
  } finally {
    sb.cleanup()
  }
})

test("doctor: project-scope MEMORY.md missing Legend → exit 1, output contains 'Missing Legend'", () => {
  const sb = makeSandbox()
  try {
    writeMemoryFile(projectScopePath(sb.home, sb.project), MISSING_LEGEND_MEMORY)
    const r = runScript(DOCTOR, [], sb)
    assert.match(r.stdout, /Missing Legend/, `expected 'Missing Legend' in stdout:\n${r.stdout}`)
    assert.equal(r.status, 1, `expected exit 1, got ${r.status}`)
  } finally {
    sb.cleanup()
  }
})

test("doctor: all three scopes have valid MEMORY.md → mentions all 3 paths, exit 0", () => {
  const sb = makeSandbox()
  try {
    const p1 = projectScopePath(sb.home, sb.project)
    const p2 = localScopePath(sb.project)
    const p3 = globalScopePath(sb.home)
    writeMemoryFile(p1, VALID_MEMORY)
    writeMemoryFile(p2, VALID_MEMORY)
    writeMemoryFile(p3, VALID_MEMORY)
    const r = runScript(DOCTOR, [], sb)
    assert.ok(r.stdout.includes(p1), `expected stdout to include ${p1}`)
    assert.ok(r.stdout.includes(p2), `expected stdout to include ${p2}`)
    assert.ok(r.stdout.includes(p3), `expected stdout to include ${p3}`)
    assert.equal(r.status, 0, `expected exit 0, got ${r.status}\nstdout:\n${r.stdout}\nstderr:\n${r.stderr}`)
  } finally {
    sb.cleanup()
  }
})

// ---------- purge ----------

test("purge: --dry-run on file with duplicates leaves file unchanged, output mentions removed entries", () => {
  const sb = makeSandbox()
  try {
    const path = localScopePath(sb.project)
    writeMemoryFile(path, MEMORY_WITH_DUPES)
    const before = readFileSync(path, "utf8")
    const r = runScript(PURGE, ["--dry-run"], sb)
    const after = readFileSync(path, "utf8")
    assert.equal(after, before, "file should be unchanged after --dry-run")
    assert.match(r.stdout, /\[duplicate\]/, `expected '[duplicate]' marker in stdout:\n${r.stdout}`)
    assert.match(r.stdout, /Run without --dry-run to apply\./)
  } finally {
    sb.cleanup()
  }
})

test("purge: real run on file with duplicate rewrites file and creates backup", () => {
  const sb = makeSandbox()
  try {
    const path = localScopePath(sb.project)
    writeMemoryFile(path, MEMORY_WITH_DUPES)
    const r = runScript(PURGE, [], sb)
    const after = readFileSync(path, "utf8")
    assert.doesNotMatch(after, /STY:foo/, "duplicate STY:foo should have been removed")
    assert.match(after, /GIT:foo/, "first occurrence GIT:foo should be kept")
    assert.match(after, /TST:bar/, "distinct entry TST:bar should be kept")

    const backupRoot = join(sb.home, ".claude", "backups", "sigil", "purge")
    assert.ok(existsSync(backupRoot), `expected backup root at ${backupRoot}`)
    const dateDirs = readdirSync(backupRoot)
    assert.ok(dateDirs.length >= 1, "expected at least one date-stamped backup dir")
    const dateDir = join(backupRoot, dateDirs[0])
    const backups = readdirSync(dateDir)
    assert.ok(backups.length >= 1, `expected at least one backup file in ${dateDir}`)
    const backedUp = readFileSync(join(dateDir, backups[0]), "utf8")
    assert.equal(backedUp, MEMORY_WITH_DUPES, "backup content should match pre-purge content")

    assert.match(r.stdout, /Backup saved to /, `expected 'Backup saved to' in stdout:\n${r.stdout}`)
    assert.match(r.stdout, /Done\./)
  } finally {
    sb.cleanup()
  }
})

test("purge: no MEMORY.md anywhere → exit 1", () => {
  const sb = makeSandbox()
  try {
    const r = runScript(PURGE, [], sb)
    assert.equal(r.status, 1, `expected exit 1, got ${r.status}\nstdout:\n${r.stdout}\nstderr:\n${r.stderr}`)
    assert.match(r.stderr + r.stdout, /No MEMORY\.md files found\./)
  } finally {
    sb.cleanup()
  }
})
