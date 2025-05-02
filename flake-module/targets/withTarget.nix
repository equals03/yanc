{
  lib,
  flake-parts-lib,
  yanc-lib,
  config,
  ...
}: let
  inherit
    (lib)
    mkOption
    ;

  inherit
    (flake-parts-lib)
    mkDeferredModuleOption
    ;

  inherit
    (yanc-lib)
    overloaded
    types
    ;

  cfg = config;

  get-target = target: cfg.allTargets.${target} or (cfg.perTarget target);
  withTarget = target: let
    args = (get-target target).allModuleArgs;
  in
    overloaded {
      string = system: f: (({withSystem, ...}: (withSystem system f)) args);
      lambda = f: f args;
    };
in {
  options = {
    perTarget = mkDeferredModuleOption ({
      target-name,
      config,
      options,
      specialArgs,
      ...
    }: {
      options = {
        allModuleArgs = mkOption {
          type = with types; lazyAttrsOf raw;
          internal = true;
          readOnly = true;
        };
      };
      config = {
        allModuleArgs =
          config._module.args // specialArgs // {inherit config options;};
      };
    });
  };

  config = {
    _module.args = {
      inherit withTarget;
    };
  };
}
