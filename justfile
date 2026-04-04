default:
    @just --list

# Build all workspace crates
build:
    cargo build --workspace

# Test all workspace crates
test:
    cargo test --workspace

# Type-check all workspace crates (fast, no codegen)
check:
    cargo check --workspace

# Lint all workspace crates
clippy:
    cargo clippy --workspace --all-targets -- -D warnings

# Run pre-commit hooks on all files, including autoformatting
pre-commit-all:
    pre-commit run --all-files

# Build idd and idd-fir binaries in release mode and install to ~/.local/bin
local-install:
    cargo build --release -p idd-cli -p idd-fir-cli
    mkdir -p ~/.local/bin
    cp target/release/idd ~/.local/bin/
    cp target/release/idd-fir ~/.local/bin/
    @echo "Installed idd and idd-fir to ~/.local/bin/"

# Push main repo and all submodules in lockstep
pushall:
    git push --recurse-submodules=on-demand

# Show git status for main repo and all submodules
statusall:
    @echo "=== idd-dev (root) ==="
    @git status --short
    @git submodule foreach --quiet 'echo "" && echo "=== $name ===" && git status --short'

# Structural quality analysis — SOLID, IOSP, coupling, DRY, SRP
quality:
    rustqual idd-fir/crates/ --no-fail
    rustqual idd/crates/ --no-fail
    rustqual idd-dsl/crates/ --no-fail

# Structural quality — fail CI if below threshold
quality-gate:
    rustqual idd-fir/crates/ --min-quality-score 80
    rustqual idd/crates/ --min-quality-score 80
    rustqual idd-dsl/crates/ --min-quality-score 80

# Install cargo-tarpaulin if not present
install-coverage:
    @echo "Installing cargo-tarpaulin..."
    cargo install cargo-tarpaulin --version 0.32.8

# Generate coverage reports for workspace
coverage:
    @echo "=== Generating coverage reports ==="
    cargo tarpaulin --out Html --output-directory target/coverage
    cargo tarpaulin --out Lcov --output-directory target/coverage
    cargo tarpaulin --out Text --output-directory target/coverage
    @echo ""
    @echo "Coverage reports available at: target/coverage/index.html"
    @echo "LCOV report: target/coverage/coverage.lcov"
    @echo "Text report: target/coverage/coverage.txt"

# Coverage for specific crate
coverage-crate:
    cargo tarpaulin --crate idd-fir-core --out Html --output-directory target/coverage-fir-core
    cargo tarpaulin --crate idd-fir-cli --out Html --output-directory target/coverage-cli
    cargo tarpaulin --crate idd-dsl-core --out Html --output-directory target/coverage-dsl

# Code health score — cognitive complexity, duplication, Halstead, maintainability
health:
    km score idd-fir/
    km score idd/
    km score idd-dsl/

# Coupling analysis — module balance, circular deps, god modules
coupling:
    cargo coupling --summary

# Full quality pipeline — all three tools
quality-all: quality health coupling
