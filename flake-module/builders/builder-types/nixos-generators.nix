{
  inputs,
  yanc-lib,
  ...
}: let
  inherit
    (yanc-lib)
    filter
    is-nixos-generators
    map
    ;

  builders-from-inputs = let
    input-to-builder = builder-fn: {
      builder = {settings, ...}: {
        system,
        modules,
        specialArgs,
        format ? "iso",
        ...
      }:
        builder-fn (settings // {inherit format system modules specialArgs;});
    };
    builder-inputs = filter (_: is-nixos-generators) inputs;
    builders = map (_: input: input-to-builder (input.nixosGenerate)) builder-inputs;
  in
    builders;
in {
  yanc.builders = builders-from-inputs;
}
