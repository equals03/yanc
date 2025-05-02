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
  cfg-realised = cfg.yanc.realised;
in {
  options = with types; {
    yanc = {
      realisePerSystem = mkOption {
        type = mkPerSystemType ({system, ...}: {
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
    yanc.realised.systems = genAttrs cfg.systems cfg.yanc.realisePerSystem;

    _module.args = {
      getRealisedSystem = system: cfg-realised.systems.${system} or (builtins.trace "using non-memoized realised system ${system}" cfg.yanc.realisePerSystem system);
    };
  };
}
