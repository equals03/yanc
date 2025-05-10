{
  inputs,
  yanc-lib,
  ...
}: let
  inherit
    (yanc-lib)
    filter
    is-darwin
    is-nixpkgs
    map
    ;

  builders-from-inputs = let
    input-to-builder = input: let
      builder-fn = input.lib.nixosSystem or input.lib.darwinSystem;
    in {
      builder = {settings, ...}: ({
        system,
        modules,
        specialArgs,
        ...
      }: (builder-fn (settings // {inherit system modules specialArgs;})));

      type = "system";
    };
    builder-inputs = filter (_: input: (is-nixpkgs input) || (is-darwin input)) inputs;
    builders = map (_: input-to-builder) builder-inputs;
  in
    builders;
in {
  yanc.builders = builders-from-inputs;
}
