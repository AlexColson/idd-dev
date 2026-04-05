---
author = "alex"
created = "2026-04-04"
depends_on = ["FIR-3"]
id = "FIR-1"
status = "scoping"
tags = ["mcp", "server", "infrastructure", "extensible"]
title = "idd serve — MCP server for all idd-* plugins"
updated = "2026-04-05"---

-

## Summary

Build `idd serve` as a subcommand of `idd-cli` that exposes all `idd-*` plugin commands as MCP tools via the `rmcp` Rust SDK. Starts with `idd fir` (15 subcommands → 15 MCP tools), designed to auto-discover and expose any future `idd-*` plugin.

## Problem

Agents (and humans) need programmatic access to the FIR registry and other IDD subcommands. Currently only a CLI exists. An MCP server provides a stable protocol interface that any MCP-capable client can consume, regardless of where data actually lives.

## Design

### Architecture

- `rmcp` server (stdio transport)
- Plugin Discovery (scan $PATH for idd-*)
- Tool Registry (auto-register tools per plugin)
- Command Executor (spawn plugin binary, capture stdout/stderr)

### Plugin Discovery
At startup, `idd serve` scans `$PATH` for binaries matching `idd-*`. For each found:
1. Run `idd-<name> --metadata` → parse JSON for description, version, mcp_tools
2. Fall back to `idd-<name> --describe` → single-line description
3. Fall back to `idd-<name> --help` → parse first non-usage line
4. Register all subcommands as MCP tools

### Tool Naming Convention
`{plugin}.{subcommand}` — e.g., `fir.new`, `fir.list`, `fir.show`

### Tool Schema Generation
Each tool's input schema is derived from the plugin's CLI arguments:
- Positional args → required string fields
- `--flag` → optional fields with appropriate types
- `--flag` (repeatable) → array fields
- `--flag` with choices → enum fields
- Description from clap doc comments

### Command Execution
When an MCP tool is called:
1. Resolve the plugin binary path from discovery cache
2. Build CLI args from tool input parameters
3. Spawn process, capture stdout/stderr
4. Return structured response (JSON if parseable, otherwise text)
5. Propagate exit codes as MCP errors

### Extensibility
The server is plugin-agnostic. Any binary named `idd-<name>` on `$PATH` that responds to `--metadata` or `--describe` will be auto-exposed. No code changes needed when new plugins are added.

## MCP Tools (Initial — from idd fir)
| Tool Name | CLI Mapping | Description |
|-----------|-------------|-------------|
| `fir.new` | `idd fir new <title> [options]` | Create a new feature, story, or decision |
| `fir.list` | `idd fir list [options]` | List features by filter criteria |
| `fir.show` | `idd fir show <id> [options]` | Show an entity with its relationships |
| `fir.promote` | `idd fir promote <id> [options]` | Advance a feature to the next natural status |
| `fir.status` | `idd fir status <id> <status>` | Set a feature's status explicitly |
| `fir.defer` | `idd fir defer <id> <reason>` | Defer a feature with a recorded reason |
| `fir.abandon` | `idd fir abandon <id> <reason>` | Abandon a feature with a recorded reason |
| `fir.link` | `idd fir link <id> [options]` | Create relationships between entities |
| `fir.decide` | `idd fir decide <title> [options]` | Create a decision record |
| `fir.graph` | `idd fir graph [options]` | Show the dependency graph |
| `fir.context` | `idd fir context [options]` | Show agent context preview |
| `fir.check` | `idd fir check [options]` | Run integrity and health checks |
| `fir.update` | `idd fir update <id> [options]` | Update feature fields |
| `fir.search` | `idd fir search <query> [options]` | Search across features, stories, decisions |
| `fir.note` | `idd fir note <id> <note> [options]` | Add a dated note to a feature |

## Implementation Plan
### Phase 1: Infrastructure
- Add `rmcp` dependency to `idd-cli/Cargo.toml`
- Create `idd-cli/src/serve/` module
- Implement stdio transport server with rmcp
- Implement plugin discovery (`find_all_plugins()`)
- Implement tool registration from discovered plugins

### Phase 2: Tool Execution
- Implement command executor (spawn plugin, capture output)
- Implement CLI arg builder from tool input params
- Implement response formatter (JSON → structured, text → fallback)
- Implement error propagation (exit codes → MCP errors)

### Phase 3: idd fir Tool Schemas
- Define input schema for each of the 15 `fir.*` tools
- Map each schema to the corresponding CLI args
- Test each tool end-to-end via MCP client

### Phase 4: Integration
- Wire `serve` subcommand into `idd-cli` main
- Add `--root` flag to serve for specifying project root
- Add graceful shutdown handling
- Add server metadata (version, available tools)

## Technical Decisions
- **Why rmcp?** Official Rust MCP SDK with derive macros, type-safe, handles JSON-RPC protocol
- **Why auto-discovery?** Matches existing idd plugin convention, zero code changes for new plugins
- **Why spawn processes?** Plugin isolation, version independence, matches existing architecture

## Success Criteria
- `idd serve` starts and listens on stdio
- All 15 `fir.*` tools discoverable via MCP `tools/list`
- Each tool executes the corresponding `idd fir` subcommand correctly
- New `idd-*` binaries on `$PATH` are auto-discovered and exposed
- Error messages from plugins propagated to MCP clients
- `cargo clippy -- -D warnings` passes
- Tests pass

## Out of Scope
- MCP resources (e.g., `fir://features/active`) — future
- MCP prompts — future
- HTTP/SSE transport — stdio only
- Plugin hot-reloading — discovery at startup only
