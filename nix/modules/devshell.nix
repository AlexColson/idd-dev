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
        pkg-config
        openssl.dev
      ];

      # Code quality tools — require Rust 1.85+ (edition2024), not yet in nixpkgs
      # Install manually: cargo install rustqual km cargo-coupling
      shellHook = ''
        addToSearchPath PATH "$HOME/.cargo/bin"
      '';
    };
  };
}
