---
author = "alex"
created = "2026-04-05"
depends_on = ["FIR-3"]
id = "FIR-5"
status = "done"
tags = ["archive", "git", "search", "idd-fir", "quality-of-life"]
title = "Archive improvements — year/month structure, git-aware moves, and search"
updated = "2026-04-05"---

-

## Summary

Improve the archiving system in `idd fir` with three connected features:
1. Year/month subdirectory structure for archived items
2. Archive listing (flat + tree views) and search with `--include-archive`
3. Git-aware archiving (auto-detect git, use `git mv`, fall back to `fs::rename`)

Decisions are **never archived** — they stay in `.fir/decisions/` as permanent records. Archived features retain their decision references.

## Design

### Archive Path Structure
- New path: `.fir/archive/YYYY/MM/FIR-N.md`
- Uses **archive date** (when the command runs), not feature's created/updated date
- `ensure_dirs()` creates `archive/YYYY/MM/` on demand

### Archive Listing
- `idd fir archive` — default flat table: `ID | Title | Status | Archived Date | Path`
- `idd fir archive --tree` — year/month tree with counts: `2026/04 (3)`

### Archive Search
- `idd fir search --include-archive` — searches both active and archived items
- Results tagged `[archived]` for archived items

### Git-Aware Archiving
- Detect if `.fir/` is in a git repo (check for `.git` in parent dirs)
- If git repo → `git mv src dst`
- If not → `std::fs::rename`

### Decisions
- Decisions are **never archived** — they remain in `.fir/decisions/` permanently
- Archived features retain their `decisions: [DEC-N]` references
- Decisions retain their `features: [FIR-N]` back-references

## Implementation Plan
### Phase 1: Archive path structure
- Update `archive_feature()` to use year/month path
- Update `ensure_dirs()` to create year/month dirs

### Phase 2: Git-aware archiving
- Add `is_git_repo()` detection
- Use `git mv` when available, fall back to `fs::rename`

### Phase 3: Archive loading and listing
- Update `load_all()` to recursively load from `archive/**/**/*.md`
- Add `list_archived()` method to backend
- Add `idd fir archive` CLI command (flat + tree views)

### Phase 4: Search integration
- Add `--include-archive` flag to `idd fir search`
- Tag archived results in output

## Success Criteria
- Archived features go to `.fir/archive/YYYY/MM/`
- `idd fir archive` shows archived items in both views
- `idd fir search --include-archive` finds archived items
- Git repos use `git mv` for archiving
- Decisions remain visible and searchable
- `cargo clippy -- -D warnings` passes
- All tests pass
