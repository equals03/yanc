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
    attrValues
    concatLists
    mergeAttrsList
    ;

  inherit
    (yanc-lib)
    compose-all
    filter
    map
    map'
    without
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
              ./default-module.nix
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
            // (mergeAttrsList [
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
      home:
        {
          ${home.name} = without ["hosts"] (home // {host = "";} // (to-host-for home {}));
        }
        // (map' (_host-name: host: {
            inherit (host) name;
            value = to-host-for home host;
          })
          home.hosts)
    )
  ];
in {
  options = {
    yanc.realised = {
      homes = mkRealisedOption {
        default = cfg-homes;
        apply = homes: (mergeAttrsList (attrValues (map (_: to-homes) homes)));
      };
    };
  };

  config = {
    _module.args.homes = realised-homes;

    yanc.systems = attrValues (map (_: home: home.system) realised-homes);

    yanc.realisePerSystem = {system, ...}: {
      options = {
        homes = mkRealisedOption {
          default = realised-homes;
          apply = filter (_: home: home.system == system);

          internal = true;
        };
      };
    };

    perSystem = {system, ...}: {
      _module.args.homes' = (getRealisedSystem system).homes;
    };
  };
}
