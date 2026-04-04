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
