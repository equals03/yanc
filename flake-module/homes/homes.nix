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
    mkAliasOptionModule
    mkOption
    path
    pathExists
    systems
    take
    ;

  inherit
    (yanc-lib)
    overloaded
    filter
    types
    ;

  cfg = config;
  cfg-yanc = cfg.yanc;
  cfg-settings = cfg-yanc.settings;
  cfg-hosts = cfg-yanc.hosts;

  cfg-homes = cfg-yanc.homes;

  append-to-search-path = let
    base = cfg-settings.homes.path;
  in
    overloaded {
      string = p: base + "/${p}";
      path = path.append base;
    };

  home-type = with types;
    submoduleWith {
      modules = [
        {freeformType = lazyAttrsOf raw;}
        ({
          name,
          config,
          ...
        }: {
          imports = [
            (mkAliasOptionModule ["specialArgs"] ["extraSpecialArgs"])
            {
              config = {
                modules = concatLists [
                  (cfg-settings.homes.shared.modules or [])
                  (take 1 (filter pathExists [
                    (append-to-search-path "${name}.nix")
                    (append-to-search-path "${name}")
                  ]))
                ];

                extraSpecialArgs = cfg-settings.homes.shared.extraSpecialArgs or {};
              };
            }
          ];

          options = {
            name = mkOption {
              type = str;
              description = ''
                The username of the Home Manager user, automatically set to the attribute name in `homes`.
                Used to set the default home username.
              '';
              default = name;

              readOnly = true;
              internal = true;
            };

            username = mkOption {
              type = str;
              description = ''
                The username of the Home Manager user, automatically set to the attribute name in `homes`.
                Used to set the default home username.
              '';
              default = name;
            };

            homeDirectory = mkOption {
              type = str;
              description = ''
                The username of the Home Manager user, automatically set to the attribute name in `homes`.
                Used to set the default home username.
              '';
              default = let
                sys = systems.elaborate config.system;
              in
                if sys.isDarwin
                then "/Users/${config.username}"
                else "/home/${config.username}";
            };

            system = mkOption {
              type = str;
              description = ''
                The system architecture or platform for the user's home environment (e.g., `x86_64-linux`, `aarch64-darwin`).
                This determines the platform for which Home Manager will build the configuration.
              '';
              example = literalExpression ''"aarch64-linux"'';
              default = builtins.currentSystem or (throw "home [${name}]: builtins.currentSystem is not available. Make sure you are using the --impure flag or explicitly set a system.");
            };

            modules = mkOption {
              type = uniqueListOf module;
              description = ''
                A list of Home Manager modules specific to the user's home environment.
                These modules define user-specific configurations, such as dotfiles, packages, or services managed by Home Manager.
              '';
              example = literalExpression ''
                [
                  ./hosts/web1.nix
                  { services.nginx.enable = true; }
                ]
              '';
              default = [];
            };

            extraSpecialArgs = mkOption {
              type = deepMergedAttrsOf raw;
              description = ''
                Extra arguments passed to the Home Manager modules for this user.
                These can be used to pass custom variables or settings to the modules, such as environment-specific configurations.
              '';
              example = literalExpression ''
                { theme = "dark"; editor = "vscode"; }
              '';
              default = {};
            };

            meta = mkOption {
              type = deepMergedAttrsOf raw;
              description = ''
                An attribute set for storing metadata about the user's home configuration.
                This can include information like user roles, preferences, or tags for documentation or external tools.
              '';
              example = literalExpression ''
                { role = "developer"; os = "macos"; priority = 2; }
              '';
              default = {};
            };

            hosts = mkOption {
              type = lazyAttrsOf (host-type name);
              description = ''
                Defines host-specific configurations for the user's home environment.
                Each host is a `host-type` submodule, allowing for host-specific Home Manager settings, such as different dotfiles or packages per machine.
              '';
              example = literalExpression ''
                {
                  laptop = {
                    system = "x86_64-darwin";
                    modules = [ ./home/hosts/laptop/alice.nix ];
                  };
                  desktop = {
                    system = "x86_64-linux";
                    modules = [ ./home/hosts/desktop/alice.nix ];
                  };
                }
              '';
              default = {};
            };
          };
        })
      ];
    };

  host-type = home-name:
    with types;
      submoduleWith {
        modules = [
          {freeformType = lazyAttrsOf raw;}
          ({
            name,
            config,
            ...
          }: {
            imports = [
              (mkAliasOptionModule ["specialArgs"] ["extraSpecialArgs"])
              {
                config = {
                  modules = concatLists [
                    (take 1 (filter pathExists [
                      (append-to-search-path "hosts/${home-name}/${name}.nix")
                      (append-to-search-path "hosts/${home-name}/${name}")
                    ]))
                  ];
                };
              }
            ];

            options = {
              name = mkOption {
                type = str;
                description = ''
                  The name of the host for the user's home configuration, automatically set to the attribute name in `yanc.homes.<home-name>.hosts`.
                  This is used internally to reference the host-specific configuration.
                '';
                default = "${home-name}@${name}";

                internal = true;
                readOnly = true;
              };
              host = mkOption {
                type = str;
                default = name;

                internal = true;
                readOnly = true;
              };

              username = mkOption {
                type = str;
                description = ''
                  The username of the Home Manager user, automatically set to the attribute name in `homes`.
                  Used to set the default home username.
                '';
                default = cfg-homes.${home-name}.username;
              };

              homeDirectory = mkOption {
                type = str;
                description = ''
                  The username of the Home Manager user, automatically set to the attribute name in `homes`.
                  Used to set the default home username.
                '';
                default = let
                  sys = systems.elaborate config.system;
                in
                  if sys.isDarwin
                  then "/Users/${config.username}"
                  else "/home/${config.username}";
              };

              system = mkOption {
                type = str;
                description = ''
                  The system architecture or platform for the host (e.g., `x86_64-linux`, `aarch64-linux`).
                '';
                example = literalExpression ''"aarch64-linux"'';
                default = cfg-hosts.${name}.system or cfg-homes.${home-name}.system;
              };

              modules = mkOption {
                type = uniqueListOf module;
                description = ''
                  A list of Home Manager modules specific to the user's configuration on this host.
                  These modules define host-specific settings, such as machine-specific dotfiles or packages.
                '';
                example = literalExpression ''
                  [
                    ./home/hosts/laptop/alice.nix
                    { programs.vscode.enable = true; }
                  ]
                '';
                default = [];
              };

              extraSpecialArgs = mkOption {
                type = deepMergedAttrsOf raw;
                description = ''
                  Extra arguments passed to the Home Manager modules for this host-specific configuration.
                  These can customize module behavior, such as setting host-specific variables.
                '';
                example = literalExpression ''
                  { hostname = "laptop"; gui = true; }
                '';
                default = {};
              };

              meta = mkOption {
                type = deepMergedAttrsOf raw;
                description = ''
                  An attribute set for storing metadata about the host-specific home configuration.
                  This can include details like the host's purpose, location, or other descriptive data.
                '';
                example = literalExpression ''
                  { purpose = "work"; location = "home"; }
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
      homes = mkOption {
        type = attrsOf home-type;
        description = ''
          A set of Home Manager configurations for different users.
          Each attribute represents a user and their home environment settings, including modules, system type, and host-specific configurations.
        '';
        example = literalExpression ''
          {
            alice = {
              system = "x86_64-darwin";
              modules = [ ./home/users/alice.nix ];
              extraSpecialArgs = { theme = "light"; };
              hosts = {
                macbook = {
                  system = "x86_64-darwin";
                  modules = [ ./home/hosts/macbook/alice.nix ];
                };
              };
            };
            bob = {
              system = "x86_64-linux";
              modules = [ ./home/users/bob.nix ];
              hosts = {
                desktop = {
                  system = "x86_64-linux";
                  modules = [ ./home/hosts/desktop/bob.nix ];
                };
              };
            };
          }
        '';
        default = {};
      };

      settings.homes = {
        path = mkOption {
          type = types.path;
          description = ''
            The filesystem path where Home Manager configuration files for users are stored.
            The module searches for a file like `<path>/<user-name>.nix` or a directory like `<path>/<user-name>/`.
          '';
          example = literalExpression ''./yanc/homes'';
          default = "${self}/homes";
        };

        shared = mkOption {
          type = submodule {
            imports = [
              (mkAliasOptionModule ["specialArgs"] ["extraSpecialArgs"])
            ];
            options = {
              modules = mkOption {
                type = uniqueListOf module;
                description = ''
                  A list of Home Manager modules to be included in all home configurations.
                '';
                example = literalExpression ''
                  [
                    ./home/hosts/laptop/alice.nix
                    { programs.vscode.enable = true; }
                  ]
                '';
                default = [];
              };

              extraSpecialArgs = mkOption {
                type = deepMergedAttrsOf raw;
                description = ''
                  Extra arguments passed to the Home Manager modules for this host-specific configuration.
                  These can customize module behavior, such as setting host-specific variables.
                '';
                example = literalExpression ''
                  { hostname = "laptop"; gui = true; }
                '';
                default = {};
              };
            };
          };
          description = ''
            Shared modules/extraSpecialArgs applied to all homes.
          '';
          default = {};
        };
      };
    };
  };
}
