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
    genAttrs
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
  cfg-settings = cfg.yanc.settings;

  target-type = with types;
    submoduleWith {
      modules = [
        {freeformType = lazyAttrsOf raw;}
        ({name, ...}: {
          imports = [
            {
              config = {
                modules = concatLists [
                  (take 1 (filter pathExists [
                    (builtins.toPath "${cfg-settings.targets.path}/${name}.nix")
                    (builtins.toPath "${cfg-settings.targets.path}/${name}/")
                  ]))
                ];
              };
            }
          ];
          options = {
            name = mkOption {
              type = types.str;
              description = ''
                The name of the target, automatically set to the attribute name of the target in `yanc.targets`.
                Used internally to reference the target.
              '';
              default = name;

              internal = true;
              readOnly = true;
            };

            modules = mkOption {
              type = uniqueListOf module;
              description = ''
                A list of Nix modules to be included for the target.
                These modules are applied to all hosts within the target, providing shared configuration such as common packages or services.
              '';
              example = literalExpression ''
                [
                  ./modules/common.nix
                  { environment.systemPackages = [ pkgs.vim ]; }
                ]
              '';
              default = [];
            };

            perSystem = mkOption {
              type = lazyAttrsOf (submodule {
                options = {
                  modules = mkOption {
                    type = uniqueListOf module;
                    description = ''
                      A list of modules specific to the given system within the target.
                      These modules are applied only to hosts running the specified system, allowing for architecture-specific configurations.
                    '';
                    example = literalExpression ''
                      [ ./modules/x86.nix ]
                    '';
                    default = [];
                  };
                  specialArgs = mkOption {
                    type = deepMergedAttrsOf raw;
                    description = ''
                      Extra arguments passed to the modules for the given system.
                      These can be used to customize module behavior based on system-specific requirements.
                    '';
                    example = literalExpression ''
                      { arch = "x86"; debug = true; }
                    '';
                    default = {};
                  };
                };
              });
              description = ''
                System-specific configurations for the target.
                An attribute set where each key is a system (e.g., `x86_64-linux`) and each value is a submodule with `modules` and `specialArgs` for tailoring configurations to specific architectures.
              '';
              example = literalExpression ''
                {
                  x86_64-linux = {
                    modules = [ ./modules/prod-x86.nix ];
                    specialArgs = { kernel = "linux-5.15"; };
                  };
                  aarch64-linux = {
                    modules = [ ./modules/prod-arm.nix ];
                  };
                }
              '';
              default = genAttrs cfg.systems (_: {});
            };

            specialArgs = mkOption {
              type = deepMergedAttrsOf raw;
              description = ''
                Extra arguments passed to all modules of the target, regardless of system.
                These are useful for defining target-wide parameters such as environment variables or flags.
              '';
              example = literalExpression ''
                { env = "staging"; logLevel = "debug"; }
              '';
              default = {};
            };

            hosts = mkOption {
              type = lazyAttrsOf host-type;
              description = ''
                Defines the hosts that belong to the target.
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
          };
        })
      ];
    };

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
                    (builtins.toPath "${cfg-settings.hosts.path}/${name}.nix")
                    (builtins.toPath "${cfg-settings.hosts.path}/${config.system}/${name}.nix")

                    (builtins.toPath "${cfg-settings.hosts.path}/${name}/")
                    (builtins.toPath "${cfg-settings.hosts.path}/${config.system}/${name}/")
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
                Used to set the default host name.
              '';
              default = name;
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
                These can be used to customize module behavior for the specific host.'';
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
          };
        })
      ];
    };
in {
  options = with types; {
    yanc = {
      targets = mkOption {
        type = attrsOf target-type;
        description = ''
          Defines a set of deployment targets, where each target represents a logical grouping of hosts or systems.
          Targets can specify shared modules, system-specific configurations, and special arguments for their hosts.
        '';
        example = literalExpression ''
          {
            production = {
              modules = [ ./modules/common.nix ];
              specialArgs = { environment = "prod"; };
              perSystem = {
                x86_64-linux = {
                  modules = [ ./modules/prod-x86.nix ];
                  specialArgs = { arch = "x86"; };
                };
              };
              hosts = {
                server1 = {
                  system = "x86_64-linux";
                  modules = [ ./hosts/server1.nix ];
                };
              };
            };
          }
        '';
        default = {};
      };
      settings.targets = {
        path = mkOption {
          type = path;
          description = ''
            The filesystem path where target-specific configuration files are stored.
            The module looks for files like `<path>/<target-name>.nix` or directories like `<path>/<target-name>/` to include as modules.
          '';
          example = literalExpression ''./yanc/targets'';
          default = builtins.toPath "${self}/targets";
        };
      };
      settings.hosts = {
        path = mkOption {
          type = with types; path;
          description = ''
            The filesystem path where host-specific configuration files are stored.
            The module searches for files like `<path>/<host-name>.nix`, `<path>/<system>/<host-name>.nix`, or directories like `<path>/<host-name>/` or `<path>/<system>/<host-name>/`.
          '';
          example = literalExpression ''./yanc/hosts'';
          default = builtins.toPath "${self}/hosts";
        };
      };
    };
  };
}
