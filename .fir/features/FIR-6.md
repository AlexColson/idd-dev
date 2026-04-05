---
id = "FIR-6"
title = "Document idd fir commands and idd serve MCP tools"
status = "designing"
created = "2026-04-05"
author = "alex"
tags = ["documentation", "idd-fir", "idd-cli"]
---

## Summary

Generate comprehensive documentation for all `idd fir` CLI subcommands and `idd serve` MCP tools, placing full docs in respective `docs/` folders and adding summary sections to each repo's README.

## Scope

### idd-fir documentation
- Document all CLI subcommands (new, list, show, promote, status, defer, abandon, link, decide, graph, context, check, update, search, note, archive, archive-list)
- Place full docs in `idd-fir/docs/commands.md`
- Add summary section to `idd-fir/README.md` pointing to full docs

### idd serve documentation
- Document all MCP tools exposed by `idd serve`
- Document plugin auto-discovery mechanism
- Place full docs in `idd/docs/serve.md`
- Add summary section to `idd/README.md` pointing to full docs

## Success Criteria
- All commands/tools documented with usage examples
- READMEs updated with feature summaries
- `cargo clippy -- -D warnings` passes
- All tests pass
