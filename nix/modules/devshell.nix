{ inputs, ... }: {
  perSystem = { config, self', pkgs, lib, ... }: {
    devShells.default = pkgs.mkShell {
      name = "idd-dev-shell";
      inputsFrom = [
        self'.devShells.rust
        config.pre-commit.devShell # See ./nix/modules/pre-commit.nix
      ];
      packages = with pkgs; [
        just
        nixd # Nix language server
        bacon
        rustup
      ];

      # Code quality tools — require Rust 1.85+ (edition2024), not yet in nixpkgs
      # Install manually: cargo install rustqual kimun cargo-coupling
      shellHook = ''
        addToSearchPath PATH "$CARGO_HOME/bin"
      '';
    };
  };
}
