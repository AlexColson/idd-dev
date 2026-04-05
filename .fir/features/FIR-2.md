---
id = "FIR-2"
title = "Skill update — MCP access to idd serve with CLI fallback"
status = "designing"
created = "2026-04-04"
author = "alex"
tags = ["skill", "mcp", "agent-tooling", "idd"]
depends_on = ["FIR-1"]
---

## Summary

Update the agent's skills/configuration to access the `idd serve` MCP server once it's running, with CLI fallback during the transition period.

## Problem

Once `idd serve` is implemented, agents need to know how to connect to it and use its tools. Currently, skills have no knowledge of the MCP server or how to invoke FIR commands programmatically.

## Design

### Two-Mode Access
1. **MCP Mode (primary)** — Connect to `idd serve` via MCP client configuration
2. **CLI Fallback** — Run `idd fir <subcommand>` directly via shell

The skill attempts MCP first; if the server is not available, it falls back to CLI transparently.

### Skill Configuration
```yaml
name: idd-mcp-access
description: Access the IDD Feature Intent Registry via MCP server (idd serve), with CLI fallback
mcp_servers:
  - name: idd-serve
    command: idd
    args: ["serve"]
    env:
      FIR_ROOT: "."
```

### CLI Fallback Mapping
All 15 `fir.*` MCP tools map to their `idd fir <subcommand>` CLI equivalents.

### Skill Behavior
1. Try MCP first — call appropriate `fir.*` tool
2. On connection failure — fall back to CLI command execution
3. Parse output — both modes return structured text; skill normalizes
4. Error handling — propagate errors from either mode consistently

### Skill File Location
- **Project-level**: `.claude/skills/idd-mcp-access/SKILL.md` — travels with the repo
- **User-level**: `~/.claude/skills/idd-mcp-access/SKILL.md` — available across projects
- Recommendation: **Both.** Project-level for definition, user-level for MCP server config.

### Skill Trigger Phrases
Auto-load when agent:
- Mentions "fir", "feature", "story", "decision" in IDD context
- Uses `idd fir` commands
- Needs to query project status or feature relationships
- Is doing feature scoping, design, or implementation

## Implementation Plan
### Phase 1: Skill Definition
- Create `.claude/skills/idd-mcp-access/SKILL.md` with:
  - Skill description and trigger phrases
  - MCP tool catalog (all 15 fir.* tools with input schemas)
  - CLI fallback mapping table
  - Usage examples for common workflows
  - Error handling guidance

### Phase 2: MCP Server Configuration
- Add MCP server config to agent harness (OpenCode/Claude/etc.)
  - Server command: `idd serve`
  - Working directory: project root

### Phase 3: CLI Fallback Implementation
- Ensure `idd fir` binary is on `$PATH` during development
- Document the fallback in the skill

### Phase 4: Testing
- Verify MCP mode works when `idd serve` is running
- Verify CLI fallback works when server is not available
- Test error propagation in both modes

## Success Criteria
- Skill file exists at `.claude/skills/idd-mcp-access/SKILL.md`
- MCP server configuration is documented and testable
- CLI fallback works with current `idd fir` implementation
- Agent can create, list, show, and update features via both modes
- Error messages are clear in both modes

## Dependencies
- `idd serve` must be implemented (FIR-1)
- `idd fir` CLI must be built and accessible

## Out of Scope
- Creating new skills beyond the MCP access skill
- Modifying the FIR data model or CLI behavior
- MCP resources or prompts (future)
