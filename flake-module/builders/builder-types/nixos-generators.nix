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
    input-to-builder = input: let
      builder-fn = input.nixosGenerate;
    in {
      builder = {settings, ...}: {
        system,
        modules,
        specialArgs,
        format ? "iso",
        ...
      }:
        builder-fn (settings // {inherit format system modules specialArgs;});

      type = "system";
    };
    builder-inputs = filter (_: is-nixos-generators) inputs;
    builders = map (_: input-to-builder) builder-inputs;
  in
    builders;
in {
  yanc.builders = builders-from-inputs;
}
