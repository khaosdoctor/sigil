import { test } from "node:test"
import assert from "node:assert/strict"
import { stripFrontmatter, extractRefPaths, analyzeEntries } from "../src/doctor.ts"

test("stripFrontmatter removes a leading --- block", () => {
  assert.equal(stripFrontmatter("---\nname: x\n---\nBODY"), "BODY")
})
test("stripFrontmatter leaves content without frontmatter unchanged", () => {
  assert.equal(stripFrontmatter("GIT:foo\nSTY:bar"), "GIT:foo\nSTY:bar")
})
test("extractRefPaths finds ~ and / paths in @()", () => {
  assert.deepEqual(extractRefPaths("REF:a@(~/foo/bar),b@(/abs/x)"), ["~/foo/bar", "/abs/x"])
})
test("extractRefPaths ignores non-path @() like @(Linear(INGEST))", () => {
  assert.deepEqual(extractRefPaths("REF:bugs@(Linear)"), [])
})
test("extractRefPaths returns [] when no @()", () => {
  assert.deepEqual(extractRefPaths("GIT:commit-single"), [])
})
test("analyzeEntries flags lines with no 3-letter domain code as bare prose", () => {
  const r = analyzeEntries(["just some prose", "GIT:ok"])
  assert.deepEqual(r.bareProse, [1])
})
test("analyzeEntries flags duplicates by body across different domains (current behavior)", () => {
  const r = analyzeEntries(["GIT:foo", "STY:foo"])
  assert.deepEqual(r.duplicates, [2])
})
test("analyzeEntries does not flag distinct entries", () => {
  const r = analyzeEntries(["GIT:foo", "STY:bar"])
  assert.deepEqual(r.duplicates, [])
})
test("analyzeEntries flags long entries over ~16 tokens", () => {
  const longLine = "GIT:" + Array.from({ length: 20 }, (_, i) => "word" + i).join(" ")
  const r = analyzeEntries([longLine])
  assert.deepEqual(r.longEntries, [1])
})
