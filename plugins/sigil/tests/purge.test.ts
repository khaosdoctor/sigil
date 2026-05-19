import { test } from "node:test"
import assert from "node:assert/strict"
import { splitFrontmatter, purgeLines } from "../src/purge.ts"

test("splitFrontmatter separates frontmatter from body", () => {
  const { frontmatter, body } = splitFrontmatter("---\na: 1\n---\nGIT:foo")
  assert.equal(frontmatter, "---\na: 1\n---\n")
  assert.equal(body, "GIT:foo")
})
test("splitFrontmatter with no frontmatter yields empty frontmatter", () => {
  const { frontmatter, body } = splitFrontmatter("GIT:foo")
  assert.equal(frontmatter, "")
  assert.equal(body, "GIT:foo")
})
test("purgeLines keeps headings, blanks, Legend, comments", () => {
  const { kept, removed } = purgeLines(["# Title", "", "Legend: x=y", "<!-- note -->"])
  assert.deepEqual(removed, [])
  assert.equal(kept.length, 4)
})
test("purgeLines removes lines with no domain code", () => {
  const { kept, removed } = purgeLines(["random prose line"])
  assert.equal(kept.length, 0)
  assert.equal(removed.length, 1)
  assert.match(removed[0], /\[no domain code\]/)
})
test("purgeLines removes duplicate entries by body, keeps first", () => {
  const { kept, removed } = purgeLines(["GIT:foo", "STY:foo"])
  assert.deepEqual(kept, ["GIT:foo"])
  assert.equal(removed.length, 1)
  assert.match(removed[0], /\[duplicate\]/)
})
test("purgeLines keeps distinct entries", () => {
  const { kept } = purgeLines(["GIT:foo", "STY:bar"])
  assert.deepEqual(kept, ["GIT:foo", "STY:bar"])
})
