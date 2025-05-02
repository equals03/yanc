{
  self,
  inputs,
  config,
  lib,
  yanc-lib,
  withSystem,
  getRealisedSystem,
  ...
}: let
  inherit
    (lib)
    genAttrs
    concatLists
    setFunctionArgs
    ;

  inherit
    (yanc-lib)
    map
    filter
    without
    merge-recursive
    compose-all
    ;

  inherit
    (yanc-lib.types)
    mkRealisedOption
    ;

  cfg = config;
  cfg-targets = cfg.yanc.targets;

  realised-targets = cfg.yanc.realised.targets;

  sanitise-host = without ["modules" "specialArgs"];
  to-host-for = target:
    compose-all [
      ## modules
      (host:
        host
        // {
          modules = concatLists [
            [
              ## channel overlay
              ({channels', ...}: {
                nixpkgs.overlays = [
                  (final: prev: {channels = (prev.channels or {}) // channels';})
                ];
              })
              ## some sensible host based defaults
              ({
                host,
                lib,
                ...
              }: {
                networking.hostName = lib.mkDefault host.name;
                nixpkgs = {
                  hostPlatform = lib.mkDefault host.system;
                };
              })
              ## some sensible nix based defaults
              ({
                config,
                lib,
                ...
              }: let
                cfg = config;
                cfg-nix = cfg.nix;
              in {
                nix = {
                  settings = {
                    # we are using flakes right?? :P
                    experimental-features = lib.mkDefault [
                      "nix-command"
                      "flakes"
                    ];

                    # match the configuration based nix path with the
                    # envrionment one - if its not available for some reason
                    nix-path = lib.mkDefault cfg-nix.nixPath;

                    # show more log lines for failed builds
                    log-lines = lib.mkDefault 20;
                  };
                };
              })
              ## include the revision of the flake that built this config (if available)
              ({
                self,
                lib,
                ...
              }: {
                system.configurationRevision = lib.mkIf (self ? rev) self.rev;
              })
            ]

            target.modules
            (target.perSystem.${host.system}.modules or [])
            host.modules
          ];
        })
      ## specialArgs
      (host:
        host
        // {
          specialArgs =
            (withSystem host.system ({
              self',
              inputs',
              channels',
              ...
            }: {inherit self self' inputs inputs' channels';}))
            // (merge-recursive [
              {
                inherit yanc-lib;
                host = sanitise-host host;
                target = sanitise-target (target // {hosts = map (_: sanitise-host) target.hosts;});
              }

              target.specialArgs
              (target.perSystem.${host.system}.specialArgs or {})
              host.specialArgs
            ]);
        })
    ];

  sanitise-target = without ["modules" "specialArgs" "perSystem"];
  to-target = compose-all [
    (
      target: let
        realised = target // {hosts = map (_: (to-host-for target)) target.hosts;};
        filter-hosts = {system, ...}: realised // {hosts = filter (_: host: host.system == system) realised.hosts;};
      in
        realised
        // setFunctionArgs filter-hosts (builtins.functionArgs filter-hosts)
    )
    sanitise-target
  ];
in {
  options = {
    yanc.realised = {
      targets = mkRealisedOption {
        default = cfg-targets;
        apply = map (_: to-target);
      };
      targetsPerSystem = mkRealisedOption {
        default = realised-targets;
        apply = targets:
          genAttrs cfg.systems (system: (map (_: target: target {inherit system;}) targets));
      };
    };
  };

  config = {
    _module.args.targets = realised-targets;

    yanc.realisePerSystem = {system, ...}: {
      options = {
        targets = mkRealisedOption {
          default = realised-targets;
          apply = map (_: target: target {inherit system;});

          internal = true;
        };
      };
    };

    perSystem = {system, ...}: {
      _module.args.targets' = (getRealisedSystem system).targets;
    };

    perTarget = {target-name, ...}: {
      _module.args.target = realised-targets.${target-name} or {};

      perSystem = {system, ...}: {
        _module.args.target' = (getRealisedSystem system).targets.${target-name};
      };
    };
  };
}
