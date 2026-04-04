{ inputs, ... }:
let
  rustFlakeInputs = {
    crane = inputs.rust-flake.inputs.crane;
    rust-overlay = inputs.rust-flake.inputs.rust-overlay;
  };
in
{
  imports = [
    inputs.rust-flake.flakeModules.nixpkgs
    # Import flake-module.nix directly (which hard-imports default-crates.nix).
    # We work around the submodule glob failure by overriding cargoToml so
    # default-crates.nix sees an empty workspace.members list.
    (import "${inputs.rust-flake}/nix/modules/flake-module.nix" rustFlakeInputs)
  ];

  # Override cargoToml to have empty workspace members — prevents
  # default-crates.nix from globbing submodule paths that don't exist
  # in the Nix store. We build via `just build` (plain cargo), so
  # nix crate discovery is unused.
  perSystem.rust-project.cargoToml = { workspace.members = [ ]; };
}
