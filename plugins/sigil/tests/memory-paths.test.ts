import { test } from "node:test"
import assert from "node:assert/strict"
import { projectSlug, memoryLocations } from "../lib/memory-paths.ts"

test("projectSlug converts leading / to leading -", () => {
  assert.equal(projectSlug("/Users/foo/bar"), "-Users-foo-bar")
})
test("projectSlug converts dots to dashes", () => {
  assert.equal(projectSlug("/Users/foo.bar/baz"), "-Users-foo-bar-baz")
})
test("projectSlug of root is a single dash", () => {
  assert.equal(projectSlug("/"), "-")
})
test("memoryLocations returns project, local, global in order with correct paths", () => {
  const locations = memoryLocations("/Users/foo", "/Users/foo")
  assert.equal(locations.length, 3)
  assert.equal(locations[0].scope, "project")
  assert.equal(locations[1].scope, "local")
  assert.equal(locations[2].scope, "global")
  assert.match(locations[0].path, /-Users-foo/)
  assert.equal(locations[0].path, "/Users/foo/.claude/projects/-Users-foo/memory/MEMORY.md")
  assert.equal(locations[1].path, "/Users/foo/.claude/memory/MEMORY.md")
  assert.equal(locations[2].path, "/Users/foo/.claude/memory/MEMORY.md")
})
