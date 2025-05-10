{
  lib,
  yanc-lib,
  ...
}: let
  inherit
    (lib)
    literalExpression
    mkOption
    ;

  inherit
    (yanc-lib)
    types
    ;

  builder-type = with types;
    submoduleWith {
      modules = [
        {freeformType = lazyAttrsOf raw;}
        ({name, ...}: {
          options = {
            name = mkOption {
              type = types.str;
              description = ''
                The name of the builder, automatically set to the attribute name of the builder in `yanc.builder`.
                Used internally to reference the builder.
              '';
              default = name;

              internal = true;
              readOnly = true;
            };

            settings = mkOption {
              type = deepMergedAttrsOf raw;
              description = ''
                Additional settings to be passed to the builder function. These settings allow customization
                of the builder's behavior, such as specifying output formats or other configuration options.
              '';
              example = literalExpression ''
                {
                  # from nixos-generators
                  customFormats = { "myFormat" = <myFormatModule>; ... };
                }
              '';
              default = {};
            };

            builder = mkOption {
              type = raw;
              description = ''
                The builder function that constructs the system configuration. This function is typically
                provided by the input (e.g., `nixosSystem` or `darwinSystem`) and is used internally to
                generate the system output based on the provided settings and arguments.
              '';
              example = literalExpression ''
                ({settings, ...}@self: ({
                  system,
                  modules,
                  specialArgs,
                  format ? "iso",
                  ...
                }: (input.nixos-generators.nixosGenerate (settings // {inherit system modules specialArgs;})));)
              '';
              readOnly = true;
              internal = true;
            };

            type = mkOption {
              type = enum ["system" "home"];
              description = ''
                The type of builder this is.
                'system' would be for nixos/darwin/nixos-generators that create a system configuration.
                'home' would be for anything responsible for making a home-manager based configuration.
              '';
              example = literalExpression ''
                "home"
              '';
              default = "system";
            };
          };
        })
      ];
    };
in {
  options = with types; {
    yanc = {
      builders = mkOption {
        type = attrsOf builder-type;
        description = ''
          A set of builders, each defining a function to construct a system configuration (e.g., NixOS or Darwin).
          Builders can be manually defined or automatically discovered from flake inputs that provide
          `nixosSystem` or `darwin System` functions.
        '';
        example = literalExpression ''
          {
            nixos = {
              builder = ({settings, ...}@self: ({
                  system,
                  modules ? [],
                  specialArgs ? {},
                  ...
                }: (input.nixpkgs.lib.nixosSystem (settings // {inherit system modules specialArgs;}))););
            };
            darwin = {
              builder = ({settings, ...}@self: ({
                  system,
                  modules ? [],
                  specialArgs ? {},
                  ...
                }: (inputs.darwin.lib.darwinSystem (settings // {inherit system modules specialArgs;}))););
            };
          }
        '';
        default = {};
      };
      settings.builders = {
        discover = mkOption {
          type = bool;
          description = ''
            Whether to automatically discover builders from flake inputs that are identified as Nixpkgs
            or Darwin inputs. If enabled, builders are created for each input providing a `nixosSystem`
            or `darwinSystem` function.
          '';
          example = literalExpression ''
            false
          '';
          default = true;
        };
      };
    };
  };
}
