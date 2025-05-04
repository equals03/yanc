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

  realised-homes = cfg.yanc.realised.homes;
in {
  options = with types; {
    perHome = mkOption {
      type = mkDeferredModuleType ({home-name, ...}: {
        # basic type checking so that i don't lose home-name along the way ;P
      });
      default = {};
      apply = modules: home-name:
        (evalFlakeModule {
            inherit inputs;
            specialArgs = {inherit home-name;};
          } {
            imports = modules;
            # make sure that the "shadow" environment has
            # the same systems
            inherit (cfg) systems;
          }).config;
    };

    allHomes = mkOption {
      type = lazyAttrsOf unspecified;
      internal = true;
    };
  };

  config = {
    allHomes = genAttrs (attrNames realised-homes) config.perHome;

    flake = lib.mkMerge (lib.mapAttrsToList
      (name: conf: conf.flake)
      cfg.allHomes);
  };
}
