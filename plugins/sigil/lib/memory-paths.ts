import { homedir } from "node:os"
import { join } from "node:path"

// Mirrors Claude Code's path-slug convention: every `/` and `.` becomes `-`,
// so a leading `/` becomes a leading `-` (matching `~/.claude/projects/-Users-...`).
// Equivalent to the shell formula: sed 's|^/||; s|[/.]|-|g' then prepend `-`.
export function projectSlug(cwd: string = process.cwd()): string {
  return cwd.replace(/[/.]/g, "-")
}

export type MemoryScope = "project" | "local" | "global"

export interface MemoryLocation {
  scope: MemoryScope
  path: string
}

export function memoryLocations(
  cwd: string = process.cwd(),
  home: string = homedir(),
): MemoryLocation[] {
  return [
    { scope: "project", path: join(home, ".claude", "projects", projectSlug(cwd), "memory", "MEMORY.md") },
    { scope: "local", path: join(cwd, ".claude", "memory", "MEMORY.md") },
    { scope: "global", path: join(home, ".claude", "memory", "MEMORY.md") },
  ]
}
