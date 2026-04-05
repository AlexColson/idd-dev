---
author = "alex"
created = "2026-04-05"
id = "FIR-7"
status = "done"
tags = ["bug", "counter", "idd-fir", "metadata"]
title = "Persist ID counters in .fir/config.toml to prevent ID reuse"
updated = "2026-04-05"---

-

## Problem

`idd fir new` reuses feature IDs that are already in use by archived features. The `Registry` counters (`next_feature_id`, etc.) are initialized from `.fir/config.toml` but never persisted back after allocation. After archiving FIR-1 through FIR-5, running `idd fir new` creates FIR-1 again.

## Root Cause

`cmd_new` calls `registry.alloc_feature_id()` which increments the in-memory counter, but the counter is never written back to `.fir/config.toml`. On the next invocation, the counter resets to whatever is in the config file (or 0 if no config exists).

## Proposed Fix

`.fir/config.toml` already has a `[counters]` section with `next_feature`, `next_story`, `next_decision`. The fix:

1. **Persist counters after allocation** — after `cmd_new` creates an entity, write the updated counters back to `.fir/config.toml`
2. **First-run initialization** — if config doesn't exist or counters are 0, scan both `features/` and `archive/` directories to find the highest existing ID and initialize counters from there
3. **Add `save_config()` to `FileBackend`** — persists `Config` to `.fir/config.toml`

### Files to change

- `idd-fir-fs/src/file_backend.rs` — add `save_config()` method
- `idd-fir-cli/src/main.rs` — call `save_config()` after `cmd_new` creates an entity
- `idd-fir-fs/src/file_backend.rs` — first-run counter initialization in `load_all()`

## Success Criteria
- `idd fir new` never reuses an ID from an archived feature
- Counter state persists across invocations via `.fir/config.toml`
- First-run correctly scans both `features/` and `archive/` to initialize counters
- All existing tests pass
- New tests for counter persistence and first-run initialization
