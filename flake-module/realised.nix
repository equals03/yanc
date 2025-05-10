{
  config,
  lib,
  flake-parts-lib,
  yanc-lib,
  ...
}: let
  inherit
    (lib)
    genAttrs
    mkOption
    unique
    ;

  inherit
    (flake-parts-lib)
    mkPerSystemType
    ;

  inherit
    (yanc-lib)
    types
    ;

  cfg = config;
  cfg-yanc = cfg.yanc;
  # cfg-hosts = cfg-yanc.hosts;
  # cfg-homes = cfg-yanc.homes;

  cfg-realised = cfg-yanc.realised;

  inherit (cfg-yanc) systems;
  # systems = unique (concatLists [
  #   cfg.systems
  #   # get all the systems from the possible hosts
  #   (mapAttrsToList (_: host: host.system) cfg-realised-hosts)
  #   # get all the systems from the possible homes
  #   #(mapAttrsToList (_: home: home.system) cfg-realised-homes)
  #   # get all the systems from the possible home->hosts
  #   #(flatten (mapAttrsToList (_: home: (mapAttrsToList (_: host: host.system) home.hosts)) cfg-realised-homes))
  # ]);

  getRealisedSystem = system: cfg-realised.systems.${system} or (builtins.trace "using non-memoized realised system ${system}" cfg.yanc.realisePerSystem system);
in {
  options = with types; {
    yanc = {
      systems = mkOption {
        type = listOf str;
        default = cfg.systems;
        apply = unique;
        internal = true;
      };
      realisePerSystem = mkOption {
        type = mkPerSystemType (_: {
          # basic type checking so that i don't lose system along the way ;P
        });
        default = {};
        apply = modules: system:
          (lib.evalModules {
            inherit modules;
            prefix = ["yanc" "realisePerSystem" system];
            specialArgs = {
              inherit system;
            };
            class = "realisePerSystem";
          }).config;

        internal = true;
      };

      realised.systems = mkOption {
        type = lazyAttrsOf unspecified;
        internal = true;
      };
    };
  };

  config = {
    yanc.realised.systems = genAttrs systems cfg.yanc.realisePerSystem;

    _module.args = {
      inherit getRealisedSystem;
    };

    perSystem = {system, ...}: {
      _module.args.realisedSystem = getRealisedSystem system;
    };
  };
}
