---
name: sigil:encode
user-invocable: true
disable-model-invocation: false
allowed-tools: Read(*)
description: "Encode plain prose into Sigil compressed format without saving. Use when the user wants to preview how something would look in Sigil, or to test compression before committing."
---

# /sigil:encode

Compress the prose in `$ARGUMENTS` into Sigil — preview only, no writes.

Format spec: `skills/remember/references/sigil-syntax.md`.
Token estimate: word count × 1.3.

## Process

1. Pick the memory type: `feedback` / `project` / `reference` / `user`.
2. Pick or propose the 3-letter domain code.
3. Compress per the format rules.

## Output

```
Input:   "Never mock the database in tests — we got burned when…"
Type:    feedback
Encoded: TST:🚫mock-db,integration-only
Tokens:  ~18 → ~5 (-72%)
```

Do not write to MEMORY.md. To save, tell the user to run `/sigil:remember`.
