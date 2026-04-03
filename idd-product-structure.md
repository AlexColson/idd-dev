# IDD — Product Structure

*This document describes the repository structure, component boundaries, and relationships for the IDD toolchain. It is the scaffolding reference for creating the initial repositories. Contents will later migrate into `.fir/` once that tooling exists.*

---

## Philosophy

IDD follows the same model as `cargo` or `git`: one root binary (`idd`) with composable subcommands, where the CLI and the MCP server are the same binary exposing the same code paths. Extensions follow the cargo-plugin convention — any binary named `idd-<name>` on `$PATH` is automatically a subcommand.

Each component is a separate repository that publishes independently to crates.io. They have different change rates, different audiences, and different semver disciplines. They are not coupled at the repo level — only at the declared dependency level.

---

## Repository Overview

```
idd-dev/                  ← temporary parent repo (never published)
├── idd/                  ← submodule: root binary + core
├── idd-dsl/              ← submodule: parser, AST, annotation format
├── idd-fir/              ← submodule: feature intent registry
└── idd-obs/              ← submodule: runtime observation (later)
```

`idd-dev` is a development convenience. It exists only during bootstrap, to hold coherent cross-repo snapshots via submodule pinning. It goes away once the crates are published to crates.io and each repo declares versioned dependencies. It should have a README stating explicitly that it is temporary scaffolding, not the canonical entry point.

---

## Components

### `idd-dsl`

**What it is:** The foundation. The grammar and type system for expressing intents, constraints, boundaries, and coupling limits. Everything else depends on this.

**Change rate:** Slow and deliberate. Breaking changes have a blast radius across the entire ecosystem. Semver discipline is strict here.

**Audience:** Any tool or binary that reads or writes IDD constraint files, including third-party extension authors.

**Crate structure:**
```
idd-dsl/
├── Cargo.toml            ← workspace root
└── crates/
    ├── idd-dsl-core/     ← AST, type model, the annotation serialization format
    ├── idd-dsl-parser/   ← grammar, parser (depends on idd-dsl-core)
    └── idd-macros/       ← proc-macro crate for #[intent(...)] annotations
```

**Key design decisions:**

- `idd-macros` is a proc-macro crate (required by the compiler to be its own crate). It validates annotations at compile time and serializes them to the format defined in `idd-dsl-core`. It is a dev-dependency by default — zero runtime footprint.
- The telemetry feature is opt-in via a Cargo feature flag:
  ```toml
  [features]
  default = []
  telemetry = ["dep:idd-obs"]
  telemetry-file = ["dep:idd-obs/file"]
  ```
  Without the feature, `idd-macros` strips itself after validation. The annotation call site never changes regardless of which mode is active.
- `idd-dsl-core` knows nothing about `idd-macros`. The dependency arrow is one-way: macros depend on core, not the reverse.
- The annotation serialization format defined in `idd-dsl-core` is the contract between `idd-macros` and the `idd` binary. Both sides must agree on it. This is the first real design task when building `idd-dsl`.

**Dependency arrow:**
```
annotated crate
    └── idd-macros (dev-dep, or dep with telemetry feature)
            └── idd-dsl-core (the format/schema)
                    ↑
                idd (binary)
        reads extracted annotations,
        cross-references against .intent files
```

`idd-dsl-core` has no knowledge of `idd-macros`. The binary is the only thing that holds both sides together.

---

### `idd-fir`

**What it is:** The feature intent registry. Tracks features, stories, decisions, and their relationships as files in the repository. The "mini Jira" that lives in `.fir/`.

**Change rate:** Fast. This is an application with UX opinions and a user-facing feature roadmap. It moves at product speed.

**Audience:** Developers using IDD on their own projects, and agents consuming structured feature context at session start.

**Crate structure:**
```
idd-fir/
├── Cargo.toml            ← workspace root
└── crates/
    ├── idd-fir-core/     ← data model: Feature, Story, Decision, relationships
    ├── idd-fir-fs/       ← file backend (reads/writes .fir/ directory)
    └── idd-fir-cli/      ← CLI subcommand set (becomes idd fir when wired into idd)
```

**Key design decisions:**

- Constraint references in feature files are opaque strings during bootstrap — just IDs like `"gdpr-deletion-propagation"`. They get tightened to real DSL types once `idd-dsl` is far enough along. `idd-fir-core` does not need to understand constraints, only reference them by ID.
- The file backend is the only backend during bootstrap. The architecture supports Jira/Linear backends later, but those are not designed yet.
- `idd-fir` is the first tool to dogfood IDD on itself — the features being built are tracked in the `.fir/` directory of the `idd-fir` repo.

**Why build this second (right after `idd-dsl`):**
`idd-fir` gives the feedback loop immediately. It is lower risk than the DSL — file I/O, a data model, a CLI — and produces something usable fast. Real signal on the FIR design (status lifecycle, relationship model, agent context output) arrives while `idd-dsl` is still being figured out.

---

### `idd`

**What it is:** The root binary. Wires all subcommands together and exposes them as both a CLI and an MCP server.

**Change rate:** Medium. Moves with the subcommand ecosystem.

**Audience:** End users, agents via MCP, CI pipelines.

**Crate structure:**
```
idd/
├── Cargo.toml            ← workspace root
└── crates/
    ├── idd-core/         ← shared types used across subcommands
    └── idd-cli/          ← binary: subcommand dispatch, MCP server (idd serve)
```

**Subcommand surface:**

| Subcommand | Responsibility |
|---|---|
| `idd intent` | Manage constraint declarations — add, remove, show, import, bind, health |
| `idd fir` | Feature intent registry — delegates to `idd-fir` |
| `idd check` | Enforcement — pre-commit, CI, blast-radius, coverage |
| `idd obs` | Runtime observation — watch, report, violations, harden |
| `idd ext` | Extension management — install, list, run, publish |
| `idd serve` | Start MCP server — every subcommand becomes an MCP tool |

**Extension protocol:** Any binary named `idd-<name>` on `$PATH` is automatically available as `idd <name>`. This follows the cargo-plugin convention exactly. `idd ext install <name>` handles discovery and installation from the registry (designed later). Extensions are third-party repos — they are never submodules of `idd-dev`.

**MCP symmetry:** `idd serve` exposes every subcommand as an MCP tool with the same code paths as the CLI. An agent calling `fir.context` and a developer running `idd fir context` hit identical logic. No drift between what agents see and what humans see.

---

### `idd-obs`

**What it is:** Runtime observation tooling. The library that `idd-macros`' telemetry feature pulls in to emit traces, metrics, and violation records at runtime.

**Change rate:** Slow initially. Designed after living with the static annotation mode long enough to know what runtime data is actually needed.

**Audience:** Any binary that has opted into `idd-macros` telemetry features.

**Status:** Not built during bootstrap. Stubbed as an optional dependency in `idd-macros` from the start so the feature flag surface is stable, but the implementation waits until there is real signal from usage.

---

## Dependency Graph

```
idd-obs  ←─────────────────────────────────────────┐
                                                    │ (optional, telemetry feature)
idd-dsl-core ←── idd-dsl-parser                    │
      ↑                                             │
idd-macros ─────────────────────────────────────────┘
      ↑
  (dev-dep or dep+feature, in annotated crates)

idd-fir-core ←── idd-fir-fs ←── idd-fir-cli
      ↑
idd-dsl-core (constraint IDs only, loosely coupled during bootstrap)

idd-core ←── idd-cli
      ↑
idd-dsl-core
idd-fir-core
idd-obs (for idd obs subcommand)
```

The key invariant: `idd-dsl-core` depends on nothing in this ecosystem. It is the foundation that everyone else builds on.

---

## Build Sequencing

1. **`idd-dsl`** — first. Defines the annotation format contract before anything else can be built. The format that `idd-macros` serializes to and `idd` reads from must be designed here before either of those can proceed.

2. **`idd-fir`** — immediately after `idd-dsl` starts taking shape. Does not need `idd-dsl` to be complete, only to have a stable ID format for constraint references. Starts tracking its own features in `.fir/` from day one.

3. **`idd`** — once `idd-dsl` and `idd-fir` have enough surface to wire together. The binary is mostly dispatch and MCP wiring — the interesting logic lives in the subcomponent crates.

4. **`idd-obs`** — after living with static annotations long enough to know what runtime data is missing. The telemetry feature flag in `idd-macros` is stubbed from the start; the implementation waits for real signal.

5. **Registry** — after the ecosystem has enough real-world usage that the repetition is obvious. Not designed during bootstrap.

---

## Repository Setup

Each repo follows this structure during bootstrap:

```
<repo>/
├── Cargo.toml          ← workspace root
├── crates/             ← individual publishable crates
├── docs/               ← design documents (migrates to .fir/ later)
│   └── *.md
└── README.md
```

The `docs/` folder in each repo holds the relevant design documents for that component. These are temporary — once `idd-fir` is usable, they migrate into `.fir/` as first-class feature and decision records.

### `idd-dev` parent repo

```
idd-dev/
├── .gitmodules
├── .cargo/
│   └── config.toml     ← [patch] entries pointing into submodule paths
├── idd/
├── idd-dsl/
├── idd-fir/
├── idd-obs/
└── README.md           ← states clearly: temporary scaffolding, not canonical
```

The `.cargo/config.toml` wires local paths without touching any submodule's committed `Cargo.toml`:

```toml
[patch.crates-io]
idd-dsl-core  = { path = "idd-dsl/crates/idd-dsl-core" }
idd-dsl-parser = { path = "idd-dsl/crates/idd-dsl-parser" }
idd-macros    = { path = "idd-dsl/crates/idd-macros" }
idd-fir-core  = { path = "idd-fir/crates/idd-fir-core" }
idd-core      = { path = "idd/crates/idd-core" }
```

When publishing begins: remove the parent repo, remove the patches, point deps at published crate versions. Each repo stands alone. Clean transition, nothing structural to unwind.

---

## Dogfooding Strategy

The tools eat each other from day one:

- `idd-fir` tracks its own features in its own `.fir/` directory
- `idd-dsl`'s design constraints are expressed as IDD intent declarations, verified by `idd check`
- The first boundary constraint worth declaring: `idd-dsl-core` must never depend on `idd-macros`
- Once `idd` is runnable, every repo in `idd-dev` runs `idd check` in CI

The recursive loop — constraints on the constraint system, tracked by the feature tracker, verified by the checker — is the proof that the system works. Or the fastest path to finding out where it doesn't.
