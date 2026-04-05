---
name: idd-mcp-access
description: Access the IDD Feature Intent Registry via MCP server (`idd serve`),
  with CLI fallback. Use when creating, listing, updating, searching, or managing
  features, stories, decisions, or the `.fir/` registry. Also use when the user
  mentions "fir", "feature", "story", "decision", "archive", or IDD workflow.
---

# IDD MCP Access — Feature Intent Registry

## How it works

Two modes, tried in order:

1. **MCP Mode (primary)** — Call `fir.*` tools via the `idd-serve` MCP server
2. **CLI Fallback** — Run `idd fir <subcommand>` directly if MCP server is unavailable

The MCP server must be running (`idd serve` on stdio). If the connection fails, fall back to CLI transparently.

## MCP Tools

| Tool | CLI Fallback | Description |
|------|-------------|-------------|
| `fir.new` | `idd fir new <title> --kind <kind> [options]` | Create a feature, story, or decision |
| `fir.list` | `idd fir list [options]` | List features (excludes archived by default) |
| `fir.list --include-archive` | `idd fir list --include-archive` | List all features including archived |
| `fir.show` | `idd fir show <id>` | Show an entity with relationships |
| `fir.promote` | `idd fir promote <id>` | Advance feature to next status |
| `fir.status` | `idd fir status <id> <status>` | Set status explicitly |
| `fir.defer` | `idd fir defer <id> <reason>` | Defer a feature |
| `fir.abandon` | `idd fir abandon <id> <reason>` | Abandon a feature |
| `fir.archive` | `idd fir archive <id>` | Archive a done/abandoned/deferred feature |
| `fir.archive-list` | `idd fir archive-list [--tree]` | List archived features |
| `fir.link` | `idd fir link <id> [options]` | Create relationships between entities |
| `fir.decide` | `idd fir decide <title> [options]` | Create a decision record |
| `fir.graph` | `idd fir graph` | Show dependency graph |
| `fir.context` | `idd fir context` | Show agent context preview |
| `fir.check` | `idd fir check` | Run integrity and health checks |
| `fir.update` | `idd fir update <id> [options]` | Update feature fields |
| `fir.search` | `idd fir search <query> [--include-archive]` | Search across all entities |
| `fir.note` | `idd fir note <id> <note>` | Add a dated note to a feature |

## Common Workflows

### Create a new feature
1. `fir.new` with title, kind (`feature`/`story`/`decision`), and optional tags/author
2. Link dependencies with `fir.link <id> --depends-on <other-id>`
3. Update status as work progresses: `fir.status <id> scoping` → `designing` → `implementing` → `verifying` → `done`

### Archive a completed feature
1. Ensure status is terminal: `fir.status <id> done` (or `abandoned`/`deferred`)
2. `fir.archive <id>` — moves to `.fir/archive/YYYY/MM/`
3. Archived features are hidden from `fir.list` by default
4. Use `fir.list --include-archive` or `fir.search --include-archive` to find them

### Check project status
1. `fir.list` — active features
2. `fir.archive-list` — archived features
3. `fir.check` — integrity validation
4. `fir.graph` — dependency visualization

## CLI Fallback Command Reference

All `fir.*` tools accept an `args` string parameter. Examples:

```
fir.list → args: "--status active"
fir.search → args: "authentication --include-archive"
fir.update → args: "FIR-1 --status done"
fir.new → args: "Add login --kind feature --tag auth"
```

## Important Notes

- **Decisions are never archived** — they remain in `.fir/decisions/` permanently
- **Archive requires terminal status** — only `done`, `abandoned`, or `deferred` features can be archived
- **Archived features are still accessible** via `fir.show <id>` and `fir.search --include-archive`
- **Feature IDs** are in the format `FIR-N` (e.g., `FIR-1`, `FIR-42`)
- **The `.fir/` directory** is the source of truth — all state lives there
