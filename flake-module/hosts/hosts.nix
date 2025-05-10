{
  self,
  config,
  lib,
  yanc-lib,
  ...
}: let
  inherit
    (lib)
    concatLists
    literalExpression
    mkOption
    pathExists
    take
    ;

  inherit
    (yanc-lib)
    types
    filter
    ;

  cfg = config;
  cfg-yanc = cfg.yanc;
  cfg-settings = cfg-yanc.settings;

  host-type = with types;
    submoduleWith {
      modules = [
        {freeformType = lazyAttrsOf raw;}
        ({
          name,
          config,
          ...
        }: {
          imports = [
            {
              config = {
                modules = concatLists [
                  (take 1 (filter pathExists [
                    "${cfg-settings.hosts.path}/${name}.nix"
                    "${cfg-settings.hosts.path}/${config.system}/${name}.nix"

                    "${cfg-settings.hosts.path}/${name}/"
                    "${cfg-settings.hosts.path}/${config.system}/${name}/"
                  ]))
                ];
              };
            }
          ];

          options = {
            name = mkOption {
              type = str;
              description = ''
                The name of the host, automatically set to the attribute name of the host in `hosts`.
                Used internally to reference the host.
              '';
              default = name;

              internal = true;
              readOnly = true;
            };

            system = mkOption {
              type = str;
              description = ''
                The system architecture or platform for the host (e.g., `x86_64-linux`, `aarch64-linux`).
              '';
              example = literalExpression ''"aarch64-linux"'';
              default = "x86_64-linux";
            };

            modules = mkOption {
              type = uniqueListOf module;
              description = ''
                A list of Nix modules specific to the host.
                These modules define host-specific configurations, such as services, packages, or settings.
              '';
              example = literalExpression ''
                [
                  ./hosts/web1.nix
                  { services.nginx.enable = true; }
                ]
              '';
              default = [];
            };

            specialArgs = mkOption {
              type = deepMergedAttrsOf raw;
              description = ''
                Extra arguments passed to the host's modules.
                These can be used to customize module behavior for the specific host.
              '';
              example = literalExpression ''
                { domain = "example.com"; port = 8080; }
              '';
              default = {};
            };

            meta = mkOption {
              type = deepMergedAttrsOf raw;
              description = ''
                An attribute set for storing metadata about the host.
                This can include arbitrary information such as roles, tags, or other descriptive data used for documentation or external tools.
              '';
              example = literalExpression ''
                { role = "web"; location = "us-east"; priority = 1; }
              '';
              default = {};
            };

            target = mkOption {
              type = nullOr str;
              default = null;
            };
          };
        })
      ];
    };
in {
  options = with types; {
    yanc = {
      hosts = mkOption {
        type = attrsOf host-type;
        description = ''
          Defines the host configurations.
          Each host is a `host-type` submodule, allowing for host-specific configurations such as system type, modules, and metadata.
        '';
        example = literalExpression ''
          {
            web1 = {
              system = "x86_64-linux";
              modules = [ ./hosts/web1.nix ];
              meta = { role = "web"; };
            };
            db1 = {
              system = "x86_64-linux";
              modules = [ ./hosts/db1.nix ];
            };
          }
        '';
        default = {};
      };
      settings.hosts = {
        path = mkOption {
          type = with types; path;
          description = ''
            The filesystem path where host-specific configuration files are stored.
            The module searches for files like `<path>/<host-name>.nix`, `<path>/<system>/<host-name>.nix`, or directories like `<path>/<host-name>/` or `<path>/<system>/<host-name>/`.
          '';
          example = literalExpression ''./yanc/hosts'';
          default = "${self}/hosts";
        };
      };
    };
  };
}
