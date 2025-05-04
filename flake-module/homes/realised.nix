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
    map'
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
  cfg-homes = cfg.yanc.homes;

  realised-homes = cfg.yanc.realised.homes;

  sanitise-host = without ["modules" "specialArgs" "extraSpecialArgs"];
  to-host-for = home:
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
              ## some sensible defaults
              ({
                home,
                lib,
                pkgs,
                ...
              }: {
                home.username = lib.mkDefault home.name;
                home.homeDirectory = lib.mkDefault (
                  if pkgs.stdenv.hostPlatform.isDarwin
                  then "/Users/${home.name}"
                  else "/home/${home.name})"
                );

                programs.home-manager.enable = lib.mkDefault true;
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
                nix = lib.mkIf (cfg-nix.package != null) {
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
            ]
            home.modules or []
            host.modules or []
          ];
        })
      ## specialArgs
      (host:
        host
        // {
          extraSpecialArgs =
            (withSystem (host.system or home.system) ({
              self',
              inputs',
              channels',
              ...
            }: {inherit self self' inputs inputs' channels';}))
            // (merge-recursive [
              {
                inherit yanc-lib;
                host = sanitise-host host;
                home = sanitise-home home;
              }

              home.extraSpecialArgs or {}
              host.extraSpecialArgs or {}
            ]);
        })
    ];

  sanitise-home = without ["modules" "specialArgs" "extraSpecialArgs" "hosts"];
  to-homes = compose-all [
    (
      home: let
        realised-homes =
          {
            ${home.name} = without ["hosts"] (home // (to-host-for home {}));
          }
          // map' (host-name: host: {
            name = "${home.name}@${host-name}";
            value = to-host-for home host;
          })
          home.hosts;
      in
        map (_: realised: let
          with-pkgs = pkgs: realised // {inherit pkgs;};
        in
          realised // setFunctionArgs with-pkgs (builtins.functionArgs with-pkgs))
        realised-homes
    )
  ];
in {
  options = {
    yanc.realised = {
      homes = mkRealisedOption {
        default = cfg-homes;
        apply = map (_: to-homes);
      };
    };
  };

  config = {
    _module.args.homes = realised-homes;

    yanc.realisePerSystem = {system, ...}: {
      options = {
        homes = mkRealisedOption {
          default = realised-homes;
          apply = map (_: filter (_: home: home.system == system));

          internal = true;
        };
      };
    };

    perSystem = {system, ...}: {
      _module.args.homes' = (getRealisedSystem system).homes;
    };

    perHome = {home-name, ...}: {
      _module.args.home = realised-homes.${home-name} or {};

      perSystem = {system, ...}: {
        _module.args.home' = (getRealisedSystem system).homes.${home-name};
      };
    };
  };
}
