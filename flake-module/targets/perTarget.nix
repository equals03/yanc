{
  inputs,
  config,
  lib,
  flake-parts-lib,
  yanc-lib,
  ...
}: let
  inherit
    (lib)
    genAttrs
    attrNames
    mkOption
    ;

  inherit
    (flake-parts-lib)
    evalFlakeModule
    mkDeferredModuleType
    ;

  inherit
    (yanc-lib)
    types
    ;

  cfg = config;

  realised-targets = cfg.yanc.realised.targets;
in {
  options = with types; {
    perTarget = mkOption {
      type = mkDeferredModuleType ({target-name, ...}: {
        # basic type checking so that i don't lose target-name along the way ;P
      });
      default = {};
      apply = modules: target-name:
        (evalFlakeModule {
            inherit inputs;
            specialArgs = {inherit target-name;};
          } {
            imports = modules;
            # make sure that the "shadow" environment has
            # the same systems
            inherit (cfg) systems;
          }).config;
    };

    allTargets = mkOption {
      type = lazyAttrsOf unspecified;
      internal = true;
    };
  };

  config = {
    allTargets = genAttrs (attrNames realised-targets) config.perTarget;

    flake = lib.mkMerge (lib.mapAttrsToList
      (name: conf: conf.flake)
      cfg.allTargets);
  };
}
