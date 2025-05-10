{
  config,
  lib,
  yanc-lib,
  getRealisedSystem,
  ...
}: let
  inherit
    (lib)
    concatLists
    mergeAttrsList
    ;

  inherit
    (yanc-lib)
    map
    without
    compose-all
    ;

  inherit
    (yanc-lib.types)
    mkRealisedOption
    ;

  cfg = config;
  cfg-targets = cfg.yanc.targets;

  to-target-for = system:
    compose-all [
      (target: let
        for-system = target.perSystem.${system} or {};
      in
        target
        // {
          modules = concatLists [target.modules (for-system.modules or [])];
          specialArgs = mergeAttrsList [target.specialArgs (for-system.specialArgs or {})];
        })
      (without ["perSystem"])
    ];
in {
  options = {
  };

  config = {
    yanc.realisePerSystem = {system, ...}: {
      options = {
        targets = mkRealisedOption {
          default = cfg-targets;
          apply = map (_: (to-target-for system));

          internal = true;
        };
      };
    };

    perSystem = {system, ...}: {
      _module.args.targets' = (getRealisedSystem system).targets;
    };
  };
}
