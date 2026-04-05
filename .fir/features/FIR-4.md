---
id = "FIR-4"
title = "Interactive UI for idd fir — TUI and lightweight web UI"
status = "wish"
created = "2026-04-04"
author = "alex"
tags = ["ui", "tui", "web", "idd-fir", "quality-of-life"]
depends_on = ["FIR-1"]
---

## Summary

Add interactive interfaces to `idd fir` so users can browse, create, and manage features without memorizing CLI flags. Two interfaces:

1. **TUI** — terminal-based UI (ratatui) for in-terminal workflow
2. **Lightweight Web UI** — single-page app served by `idd serve` for browser access

## Problem

The current `idd fir` CLI requires knowing specific subcommands and flags for every operation. Browsing features, checking status, and navigating relationships is cumbersome compared to a visual interface.

## Design

### TUI (ratatui)
- Feature list with filtering (status, tags, story)
- Feature detail view with relationships graph
- Quick actions: create, promote, update status, add notes
- Keyboard-driven navigation (vim-like bindings)
- Runs as `idd fir tui`

### Web UI
- Served by `idd serve` alongside MCP tools
- Single-page app (no build step — vanilla JS or htmx + HTMX templates)
- Same capabilities as TUI: browse, filter, create, update
- Accessible at `http://localhost:PORT/` when `idd serve` is running
- Zero-config — works out of the box

## Implementation Plan
### Phase 1: TUI
- Add `ratatui` and `crossterm` dependencies to `idd-fir-cli`
- Create `idd-cli/src/tui/` module
- Feature list view with status/tag filters
- Feature detail view with body and relationships
- Create/edit forms
- `idd fir tui` subcommand

### Phase 2: Web UI
- Serve static HTML/JS from `idd serve`
- Feature list, detail, create/edit pages
- API calls to the same backend the MCP tools use
- `idd serve` exposes web UI at `/` path

## Technical Decisions
- **Why ratatui?** De facto standard Rust TUI library, active ecosystem
- **Why lightweight web UI?** No npm/webpack complexity — serve static files directly from the Rust binary
- **Why depends on FIR-1?** Web UI served by `idd serve`; TUI can reuse the same backend abstractions

## Success Criteria
- `idd fir tui` launches an interactive terminal interface
- Can browse, filter, create, and update features via TUI
- Web UI accessible when `idd serve` is running
- Both interfaces support all core FIR operations
- `cargo clippy -- -D warnings` passes

## Out of Scope
- Mobile app
- Real-time collaboration
- Advanced search/filtering beyond what CLI supports
- Custom themes (use default ratatui/browser styles initially)
