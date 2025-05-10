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
    input-to-builder = input: let
      builder-fn = input.lib.homeManagerConfiguration;
    in {
      builder = {settings, ...}: {
        system,
        modules,
        extraSpecialArgs,
        pkgs ? import input.inputs.nixpkgs {inherit system;},
        ...
      }:
        builder-fn (settings // {inherit modules extraSpecialArgs pkgs;});

      type = "home";
    };
    builder-inputs = filter (_: is-home-manager) inputs;
    builders = map (_: input-to-builder) builder-inputs;
  in
    builders;
in {
  yanc.builders = builders-from-inputs;
}
