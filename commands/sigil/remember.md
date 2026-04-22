# /sigil:remember

Save a memory in Sigil compressed format.

## Usage

```
/sigil:remember <description>
```

Or describe naturally:

```
/sigil:remember I prefer TypeScript strict mode
/sigil:remember never use var, always const
/sigil:remember API calls go in src/api/
```

## What it does

1. Interprets your description
2. Compresses into Sigil symbolic format
3. Appends to `MEMORY.md` in the appropriate scope

## Examples

| Input | Sigil Output |
|-------|--------------|
| `never use var` | `🚫var` |
| `prefer const over let` | `const▸let` |
| `API files in src/api/` | `API→src/api/` |
