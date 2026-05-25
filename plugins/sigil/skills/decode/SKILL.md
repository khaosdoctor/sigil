---
name: sigil:decode
user-invocable: true
disable-model-invocation: false
allowed-tools: Read(*)
description: "Decode a Sigil-compressed snippet back into plain prose. Use when the user wants to verify what a Sigil entry means, or when reading memory entries that need human-readable explanation."
---

# /sigil:decode

Translate the Sigil snippet in `$ARGUMENTS` into plain prose.

Format spec: `skills/remember/references/sigil-syntax.md` (read the Legend first to interpret `▸` etc).
Token estimate: word count × 1.3.

## Output

```
Input:   STY:🚫vowel-strip,readable-words▸symbols
Decoded: Never strip vowels. Prefer readable words over symbols in Sigil entries.
Tokens:  ~5 → ~18 (+260%)
```

If `$ARGUMENTS` is empty, ask for a snippet.
