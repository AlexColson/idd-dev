# Testing Strategy for idd-dev

**Generated:** 2026-04-04
**Status:** In Progress

## Executive Summary

This document outlines the testing strategy for the IDD (Intent-Driven Development) ecosystem. Current coverage is 34.73% (431/1241 lines), with target of >80% line coverage and >70% branch coverage.

## Current State

### Coverage Metrics
- **Line Coverage:** 34.73% (431/1241 lines)
- **Branch Coverage:** ~25% (estimated)
- **Untested Functions:** 51 functions (per rustqual TQ-003)

### Coverage by Crate
| Crate | Coverage | Status |
|-------|----------|--------|
| idd-fir-core/query.rs | 77.59% | ✅ Good |
| idd-fir-core/model.rs | 71.72% | ✅ Good |
| idd-fir-core/memory.rs | 54.84% | ⚠️ Needs work |
| idd-fir-core/integrity.rs | 68.24% | ⚠️ Needs work |
| idd-fir-cli/main.rs | 22.11% | ❌ Critical |
| idd-fir-fs/file_backend.rs | 0% | ❌ Critical |
| idd-dsl-core/declaration.rs | 54.84% | ⚠️ Needs work |
| idd-cli/main.rs | 0% | ❌ Critical |

## Testing Categories

### 1. Unit Tests (Primary)

**Location:** `#[cfg(test)]` modules alongside production code

**Coverage Goals:**
- Every public function has at least one test
- All error paths tested, not just happy paths
- Property-based testing (proptest) for invariants

**Examples Implemented:**
- ✅ Query builder filters (status, tag, depends_on, stale/recent)
- ✅ Graph traversal (transitive dependencies with cycles)
- ✅ ID allocation (sequential, unique, format validation)
- ✅ Status state machine (monotonic, terminal states)
- ✅ Serialization roundtrips (JSON, TOML)
- ✅ File backend atomic writes and read-after-write consistency

**Test Invariants:**
- **Atomic writes**: Temp+rename pattern preserves data integrity
- **Roundtrip consistency**: Read after write returns same data
- **Search correctness**: Results are subset of registry, case-insensitive
- **ID allocation**: Sequential incrementing, unique per kind
- **Multiple operations**: State persists correctly across mutations

### 2. Integration Tests

**Location:** `tests/` directory at crate root

**Coverage Goals:**
- CLI command integration
- Backend I/O operations
- Cross-crate API contracts

**Implemented:**
- ✅ CLI unit tests (proptest for note, promote, link commands)
- ⚠️ File backend integration tests (missing)

### 3. Property-Based Tests (PBT)

**Library:** `proptest`

**Philosophy:** Test invariants, not just lines of code. Property-based testing automatically generates thousands of test cases to verify that our code behaves correctly under all possible inputs.

**Use Cases:**
- Parsers (malformed input rejection)
- ID generators (uniqueness, sequential)
- State machines (invariants)
- Roundtrip conversions
- Constraint validation
- Search correctness (query results are subset of registry)
- File operations (atomic writes, consistency)

**Test Patterns:**
```rust
proptest! {
    #[test]
    fn test_invariant_property(
        input in arb_input(),  // Random generation
    ) {
        // Test that invariant always holds
        let result = process(input);
        assert!(result.is_valid());
    }
}
```

**Implemented:**
- ✅ Status state machine (8 variants, monotonic transitions)
- ✅ ID generation (1000+ iterations, sequential, unique)
- ✅ JSON parsing (malformed, unknown variants, edge cases)
- ✅ Serialization roundtrips (title, description, body, status preserved)
- ✅ File backend atomic writes (temp+rename preserves data)
- ✅ Search invariants (results are subset of registry, case-insensitive)
- ✅ Query builder filters (combined filters compose correctly)

**Why PBT > Manual Examples:**
- **Coverage**: 1000+ test cases vs. 5-10 hand-written examples
- **Edge cases**: PBT finds edge cases we didn't think of
- **Confidence**: Statistical guarantee of correctness
- **Maintainability**: One property test replaces dozens of unit tests

### 4. Fuzz Testing

**Strategy:** Test against random/bad input

**Use Cases:**
- Parser robustness (TOML, JSON frontmatter)
- Query builder with edge cases
- ID allocation with concurrent access (future)

**Priority:** Medium

### 5. End-to-End Tests

**Strategy:** Full workflow from CLI invocation to result

**Use Cases:**
- `idd fir new` → file creation
- `idd fir list` → output parsing
- Complete lifecycle (create → promote → link)

**Priority:** Low (for bootstrap phase)

### 6. Contract Testing

**Strategy:** Verify crate interfaces match expectations

**Use Cases:**
- `FirBackend` trait implementations
- Registry API contracts
- Query result types

**Priority:** Medium

## Testing Patterns

### Test Structure

```rust
#[cfg(test)]
mod tests {
    use super::*;
    use proptest::prelude::*;

    // Helper functions for test setup
    fn setup_registry() -> Registry { ... }

    // Unit tests
    #[test]
    fn test_feature_name() { ... }

    // Property-based tests
    proptest! {
        #[test]
        fn test_invariant_property(
            input in arb_input(),
        ) {
            // Test invariant
        }
    }

    // Negative case tests
    #[test]
    fn test_rejects_invalid_input() { ... }
}
```

### Test Naming Convention

- `test_<functionality>_<scenario>` - Unit tests
- `test_<invariant>_<property>` - PBT
- `test_<command>_<edge_case>` - Integration tests

### Test Organization

```rust
mod tests {
    // State machine invariants
    // ── FeatureStatus state machine invariants ──────────────

    // ID generation invariants  
    // ── ID generation invariants ────────────────────────────

    // Serialization roundtrips
    // ── Serialization roundtrips ────────────────────────────

    // Invalid input rejection
    // ── Invalid input rejection ─────────────────────────────
}
```

## Testing Checklist

### Unit Tests (TQ-001)
- [ ] Every public function has a test
- [ ] Error paths are tested
- [ ] Edge cases covered

### Property-Based Tests (TQ-002)
- [ ] Invariants expressed as properties
- [ ] 1000+ test iterations minimum
- [ ] Both positive and negative cases

### Coverage (TQ-003)
- [ ] Line coverage > 80%
- [ ] Branch coverage > 70%
- [ ] Untested functions < 10

### Code Quality
- [ ] No clippy warnings
- [ ] No allow without comment
- [ ] Tests are deterministic

## Priority Queue

### ✅ Completed
- ✅ File backend tests (atomic writes, search invariants, consistency) - 13 unit tests + 3 proptest suites
- ✅ Query builder tests (status, tag, stale/recent, depends_on, blocks, constraints) - 13 tests
- ✅ Graph traversal tests (simple deps, max depth, no deps, cycles) - 4 tests

### High Priority
1. **CLI commands tests** - promote, link, list, show, update (1737 lines, 5.7%)
2. **DSL utility tests** - enforcement, import, scope, severity (~74 lines, 0%)
3. **Integrity checker tests** - constraint validation, duplicate detection
4. **Memory backend tests** - alternative to file backend

### Medium Priority
1. **DSL parser tests** - grammar validation, malformed input
2. **Macro expansion tests** - proc-macro correctness
3. **Coverage tooling** - branch coverage measurement
4. **Frontmatter parser tests** - edge cases

### Low Priority
1. **E2E workflow tests** - Full CLI workflows
2. **Fuzz testing** - Random input validation
3. **Performance tests** - Benchmarking

## Testing Tools

| Tool | Purpose | Status |
|------|---------|--------|
| `cargo test` | Unit tests | ✅ Active |
| `cargo tarpaulin` | Coverage reporting | ✅ Active |
| `proptest` | Property-based testing | ✅ Active |
| `rustqual` | Code quality analysis | ⚠️ Needs setup |
| `cargo clippy` | Linting | ✅ Active |
| `cargo fmt` | Formatting | ✅ Active |

## Test Distribution

| Test Type | Count | Coverage |
|-----------|-------|----------|
| Unit tests | ~43 | ✅ Query, graph, ID, status |
| Property-based tests | ~15 | ✅ Invariants, roundtrips |
| Integration tests | ~43 | ✅ CLI commands |
| File backend tests | 13 unit + 3 proptest | ✅ Atomic writes, search |

## Test Driven Development (TDD) Workflow

```bash
# 1. Write failing test
cargo test test_new_feature -- --exact
# Expected: FAILED

# 2. Implement minimum code
# ...

# 3. Make test pass
cargo test test_new_feature -- --exact
# Expected: ok

# 4. Refactor with tests as guardrails
cargo test --lib
# Expected: all pass
```

## Continuous Integration

### Pre-Merge Checklist
- [ ] `cargo test --workspace` passes
- [ ] `cargo clippy --workspace -- -D warnings` passes
- [ ] Coverage > 80% (ideally 85%+)
- [ ] No new clippy warnings

### CI Pipeline
```yaml
test:
  - cargo test --workspace
  - cargo clippy --workspace -- -D warnings
  - cargo tarpaulin --out Xml
  - check coverage thresholds
```

## Future Enhancements

### 1. Benchmarking
- Add `criterion` for performance testing
- Test hot paths: query execution, graph traversal
- Establish performance baselines

### 2. Snapshot Testing
- For serialization formats
- For CLI output formatting

### 3. Integration with Linters
- Add `taplo` for TOML linting
- Add `rustfmt` for formatting checks

### 4. Test Coverage Dashboard
- Generate HTML reports in PR comments
- Track coverage trends over time

## Glossary

- **PBT**: Property-Based Testing (proptest)
- **TDD**: Test-Driven Development
- **E2E**: End-to-End testing
- **Panic**: Unrecoverable error in Rust
- **Invariant**: Property that must always hold true
