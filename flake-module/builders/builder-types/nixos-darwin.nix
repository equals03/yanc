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
    input-to-builder = builder-fn: {
      builder = {settings, ...}: ({
        system,
        modules,
        specialArgs,
        ...
      }: (builder-fn (settings // {inherit system modules specialArgs;})));
    };
    builder-inputs = filter (_: input: (is-nixpkgs input) || (is-darwin input)) inputs;
    builders = map (_: input: input-to-builder (input.lib.nixosSystem or input.lib.darwinSystem)) builder-inputs;
  in
    builders;
in {
  yanc.builders = builders-from-inputs;
}
