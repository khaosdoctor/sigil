# /sigil:init

Migrate all existing memory files to Sigil compressed format.

## Usage

```
/sigil:init
```

## What it does

1. **Discovers** all memory locations (global, project, session)
2. **Inventories** existing memories with token counts
3. **Compresses** each memory into Sigil format
4. **Backs up** originals to `~/.claude/backups/sigil/memories/`
5. **Rewrites** memories in Sigil format

## Example output

```
Before: 516 tokens (prose)
After:  132 tokens (Sigil)
Saved:  384 tokens (3.9× compression)
```
