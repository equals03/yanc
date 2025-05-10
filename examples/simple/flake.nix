{
  inputs = {
    nixpkgs.follows = "nixpkgs-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11/";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    yanc.url = "github:equals03/yanc";
  };

  outputs = {flake-parts, ...} @ inputs:
    flake-parts.lib.mkFlake {inherit inputs;} ({useYanc, ...}: {
      imports = [
        inputs.yanc.flakeModule
      ];

      systems = ["x86_64-linux"];

      yanc.hosts = {
        host1 = {
          # List of additional NixOS modules to include for this host.
          # These modules supplement the automatic configuration sourced from (configurable):
          # 1. `./hosts/host1.nix` (if it exists), or
          # 2. All `.nix` files in `./hosts/host1/**/*.nix` (recursively).

          # Module Resolution Notes:
          # - If the specified path is a directory, all `.nix` files are recursively included.
          # - Files or directories prefixed with an underscore (`_`) are ignored during recursion.
          # - Recursion stops if a `default.nix` file is found in the directory.
          # - The resolution logic prioritizes a single `host1.nix` file over recursive sourcing.

          # Use this to define ad-hoc or custom modules specific to this host.
          modules = [
          ];

          # Custom arguments to pass to this host's configuration modules.
          # These are accessible within the module's scope as `specialArgs`.
          # Example: `{ customOption = "value"; }` makes `customOption` available.
          specialArgs = {
          };
        };
      };

      flake.nixosConfigurations = useYanc.to.build.hosts.using.nixpkgs {};
    });
}
