{
  inputs = {
    nixpkgs.follows = "nixpkgs-stable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11/";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    nix-darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

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
    flake-parts.lib.mkFlake {inherit inputs;} (
      {useYanc, ...}: {
        imports = [
          inputs.yanc.flakeModule
          inputs.home-manager.flakeModules.home-manager
        ];

        # set to true if you want to see the inner workings.
        # hint: you don't ;)
        #debug = true;

        # systems = ["x86_64-linux" "x86_64-darwin"];
        systems = ["x86_64-linux"];

        yanc.settings = {
          hosts.path = ./yanc/hosts;
          targets.path = ./yanc/targets;
          homes.path = ./yanc/homes;
        };

        yanc.builders.nixos-generators = {
          settings = {
            customFormats = {
              custom-iso = {modulesPath, ...}: {
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
          desktop = {
            meta = {
              target-meta = true;
            };
            perSystem.x86_64-darwin = {specialArgs = {darwin-host = true;};};
            perSystem.x86_64-linux = {specialArgs = {linux-host = true;};};
          };
        };

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

            target = "desktop";
          };

          host2 = {
            target = "does-not-exist"; # but still fine

            # Hosts are a freeformType - anything can be added.
            # in this case the nixos-generator builder will use `format`
            format = "custom-iso";
            is-package = true;
          };

          host3 = {
            target = "desktop";

            system = "x86_64-darwin";
          };
        };

        yanc.homes = {
          me = {
            # if not specified will use builtins.currentSystem which will require
            # the --impure flag.
            system = "x86_64-linux";

            extraSpecialArgs = {
              top-level = true;
            };

            hosts = {
              host1 = {
                specialArgs = {
                  linux-alias = true;
                };
              };
              host3 = {
              };
            };
          };
        };

        flake = {
          nixosConfigurations = (useYanc.to.build.linux.hosts.excluding {is-package = true;}).using.nixpkgs {};
          darwinConfigurations = (useYanc.to.build.darwin.hosts.excluding {is-package = true;}).using.nix-darwin {};

          homeConfigurations = useYanc.to.build.homes.using.home-manager {};
        };

        perSystem = {system, ...}: {
          packages = (useYanc.to.build.hosts.matching {
            inherit system;
            is-package = true;
          }).using.nixos-generators {};
        };
      }
    );
}
