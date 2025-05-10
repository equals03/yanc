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
    map
    filter
    without
    overloaded
    compose-all
    ;

  inherit
    (yanc-lib.types)
    mkRealisedOption
    ;

  cfg = config;
  cfg-yanc = cfg.yanc;

  realised-hosts = cfg-yanc.realised.hosts;
  cfg-hosts = cfg-yanc.hosts;

  get-target-for = system: let
    default-target = {
      name = "";
      meta = {};
      modules = [];
      specialArgs = {};
    };
  in
    overloaded
    {
      string = name: (getRealisedSystem system).targets.${name} or (default-target // {inherit name;});
      default = default-target;
    };

  to-host = compose-all [
    (
      host: {
        inherit host;
        target = get-target-for host.system host.target;
      }
    )
    ({
      host,
      target,
    }: let
      sanitised-host = without ["modules" "specialArgs" "target"] host;
      sanitised-target = without ["modules" "specialArgs" "perSystem"] target;
    in
      host
      // {target = sanitised-target;}
      // {
        modules = concatLists [
          [
            ./default-module.nix
          ]
          (target.modules or [])
          (host.modules or [])
        ];

        specialArgs = mergeAttrsList [
          (withSystem host.system ({
            self',
            inputs',
            channels',
            ...
          }: {inherit self self' inputs inputs' channels';}))
          {
            inherit yanc-lib;
            host = sanitised-host;
            target = sanitised-target;
          }
          (target.specialArgs or {})
          (host.specialArgs or {})
        ];
      })
  ];
in {
  options = {
    yanc.realised = {
      hosts = mkRealisedOption {
        default = cfg-hosts;
        apply = map (_: to-host);
      };
    };
  };

  config = {
    _module.args.hosts = realised-hosts;

    yanc.systems = attrValues (map (_: host: host.system) realised-hosts);

    yanc.realisePerSystem = {system, ...}: {
      options = {
        hosts = mkRealisedOption {
          default = realised-hosts;
          apply = filter (_: host: host.system == system);
          internal = true;
        };
      };
    };

    perSystem = {system, ...}: {
      _module.args.hosts' = (getRealisedSystem system).hosts;
    };
  };
}
