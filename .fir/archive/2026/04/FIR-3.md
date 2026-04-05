---
author = "alex"
created = "2026-04-04"
id = "FIR-3"
status = "done"
tags = ["bug", "parser", "idd-fir", "quality-of-life"]
title = "Fix frontmatter parser to support TOML multiline strings"
updated = "2026-04-05"---

-

## Problem

The `idd fir new --body` command fails when the body content contains triple backticks (code blocks) or other characters that conflict with TOML multiline string delimiters. The frontmatter parser in `idd-fir-fs` does not properly handle TOML's multiline literal strings.

This was discovered when trying to create FIR features with code blocks in the body — the parser choked because the body was being stored as a TOML `"""..."""` multiline string in the frontmatter, and code blocks inside it broke the TOML parser.

## Current Behavior

`idd fir new --body "content with code blocks"` produces:
```
Error: failed to load FIR registry: parse error: failed to parse frontmatter TOML
```

The `idd fir new` command writes the body into the TOML frontmatter using `"""` delimiters, which breaks when the body itself contains characters that confuse the TOML parser.

## Expected Behavior

The parser should correctly handle:
- TOML multiline basic strings with any content
- Code blocks (triple backticks) in body content
- Escaped characters within strings
- Arbitrary markdown content in the body field

## Root Cause

Likely in `idd-fir-fs/src/frontmatter.rs` — the frontmatter extraction or TOML parsing step does not correctly handle multiline string delimiters when the body content contains special characters.

## Success Criteria
- `idd fir new --body` works with arbitrary content including code blocks
- Existing feature files continue to parse correctly
- Tests cover multiline string edge cases
- `cargo clippy -- -D warnings` passes
