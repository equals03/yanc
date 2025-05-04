{
  inputs,
  yanc-lib,
  ...
}: let
  inherit
    (yanc-lib)
    filter
    is-home-manager
    map
    ;

  builders-from-inputs = let
    input-to-builder = builder-fn: {
      builder = {settings, ...}: {
        modules,
        extraSpecialArgs,
        pkgs,
        ...
      }:
        builder-fn (settings // {inherit modules extraSpecialArgs pkgs;});
    };
    builder-inputs = filter (_: is-home-manager) inputs;
    builders = map (_: input: input-to-builder (input.lib.homeManagerConfiguration)) builder-inputs;
  in
    builders;
in {
  yanc.builders = builders-from-inputs;
}
