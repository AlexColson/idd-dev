{ inputs, ... }:
{
  imports = [
    inputs.rust-flake.flakeModules.default
    inputs.rust-flake.flakeModules.nixpkgs
  ];
  # No packages defined here — idd-dev is a workspace root only.
  # Packages (idd, idd-dsl, idd-fir, ...) are built from their submodule crates.
  # When submodule members are added to Cargo.toml, packages will appear here.
}
