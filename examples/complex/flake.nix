{
  inputs = {
    nixpkgs.follows = "nixpkgs-stable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11/";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    yanc.url = "github:equals03/yanc";
  };

  outputs = {flake-parts, ...} @ inputs:
    flake-parts.lib.mkFlake {inherit inputs;} ({
      lib,
      yanc-lib,
      withTarget,
      withHome,
      ...
    }: {
      imports = [
        inputs.yanc.flakeModule
        inputs.home-manager.flakeModules.home-manager
      ];

      debug = true;
      systems = ["x86_64-linux" "x86_64-darwin"];

      yanc.builders.nixos-generators = {
        settings = {
          customFormats = {
            custom-iso = {
              config,
              modulesPath,
              ...
            }: {
              imports = ["${toString modulesPath}/installer/cd-dvd/installation-cd-base.nix"];
              formatAttr = "isoImage";
              fileExtension = ".iso";

              # something else here!
            };
          };
        };
      };

      # flesh out usage
      yanc.targets = {
        nixos = {
          hosts = {
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
        };
        iso = {
          hosts.host2 = {
            # Hosts are a freeformType - anything can be added.
            # in this case the nixos-generator builder will use this
            format = "custom-iso";
          };
        };
      };

      yanc.homes = {
        me = {
          extraSpecialArgs = {
            top-level = true;
          };
          hosts = {
            linux-host = {
              specialArgs = {
                linux-alias = true;
              };
            };
            darwin-host = {
              system = "x86_64-darwin";
            };
          };
        };
      };

      perHome = {
        home,
        builders,
        withSystem,
        ...
      }: {
        flake.homeConfigurations =
          yanc-lib.map (_: home': (
            withSystem home'.system (
              {channels', ...}:
                builders.home-manager (home' channels'.nixpkgs-unstable)
            )
          ))
          home;
      };

      perSystem = {
        system,
        builders,
        ...
      }: {
        packages = withTarget "iso" system ({target', ...}: yanc-lib.map (_: builders.nixos-generators) target'.hosts);
      };

      flake.nixosConfigurations = withTarget "nixos" ({
        target,
        builders,
        ...
      }:
        yanc-lib.map (_: builders.nixpkgs-unstable) target.hosts);
    });
}
