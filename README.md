# idd-dev

**Temporary development scaffolding. Not the canonical entry point.**

This repo exists only during bootstrap. Its sole purpose is to hold coherent
cross-repo snapshots via submodule pinning and to provide a single Cargo
workspace root so all component crates can be built and tested together.

Once the component crates are published to crates.io and each repo declares
versioned dependencies, this repo goes away.

---

## Structure

```
idd-dev/
├── .cargo/config.toml   ← [patch.crates-io] overrides (local paths, not committed to submodules)
├── Cargo.toml           ← workspace root (members added as submodules are initialized)
├── idd-dsl/             ← submodule: parser, AST, annotation format
├── idd-fir/             ← submodule: feature intent registry
├── idd/                 ← submodule: root binary + core
└── idd-obs/             ← submodule: runtime observation (later)
```

## Usage

```bash
# Enter dev shell
nix develop

# Build everything
cargo build --workspace

# Test everything
cargo test --workspace

# Check everything (fast, no codegen)
cargo check --workspace
```

## Adding a submodule

1. `git submodule add <url> <name>`
2. Uncomment the corresponding `members` line in `Cargo.toml`
3. Uncomment the corresponding `[patch.crates-io]` entries in `.cargo/config.toml`
   for any cross-submodule crate references

## Design reference

See `idd-product-structure.md` for the component breakdown, dependency graph,
and build sequencing rationale.
