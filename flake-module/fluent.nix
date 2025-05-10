# A modular fluent interface for building NixOS hosts
{
  config,
  lib,
  yanc-lib,
  ...
}: let
  inherit
    (lib)
    id
    matchAttrs
    flip
    systems
    ;

  inherit
    (yanc-lib)
    compose-all
    map
    filter
    overloaded
    ;

  cfg = config;
  cfg-yanc = cfg.yanc;
  realised-builders = cfg-yanc.realised.builders;

  realised-hosts = cfg-yanc.realised.hosts;
  realised-homes = cfg-yanc.realised.homes;

  # useYanc.to.build.host.host1.using.nixpkgs {}; # build specific host
  # (useYanc.to.build.hosts.matching (host: host.target.name == "nixos")).using.nixpkgs {}; # build filtered hosts
  # useYanc.to.build.hosts.using.nixpkgs {}; # build all hosts
  fluent-build-for = {
    name,
    entities,
    builders,
  }: let
    build = builder:
      overloaded {
        set = args: entity: builder (entity // args);
        lambda = fn: entity: builder (entity // (fn entity));
      };

    build-all = entities: builder: args: map (_: build builder args) entities;

    negate = predicate: (v: !(predicate v));
    to-match-predicate = overloaded {
      set = matchAttrs;
      lambda = id;
    };
    match = predicate: filter (_: predicate);
  in {
    "${name}s" = let
      using-builder = entities: predicate: let
        matched = match predicate entities;
      in {
        _matched = matched;
        matching = compose-all [to-match-predicate (using-builder matched)];
        excluding = compose-all [to-match-predicate negate (using-builder matched)];

        using = map (_: build-all matched) builders;
      };
    in
      using-builder entities (_: true);

    "${name}" =
      map (_: entity: {
        using = (map (_: (flip build) entity)) builders;
      })
      entities;
  };

  match-system = pattern: entity: let
    sys = systems.elaborate entity.system;
  in
    matchAttrs pattern sys;
in {
  config = {
    _module.args = {
      useYanc = {
        to.build =
          {
            darwin =
              fluent-build-for {
                name = "host";
                entities = filter (_: match-system {isDarwin = true;}) realised-hosts;
                builders = realised-builders.system;
              }
              // fluent-build-for {
                name = "home";
                entities = filter (_: match-system {isDarwin = true;}) realised-homes;
                builders = realised-builders.home;
              };
            linux =
              fluent-build-for {
                name = "host";
                entities = filter (_: match-system {isLinux = true;}) realised-hosts;
                builders = realised-builders.system;
              }
              // fluent-build-for {
                name = "home";
                entities = filter (_: match-system {isLinux = true;}) realised-homes;
                builders = realised-builders.home;
              };
          }
          // fluent-build-for {
            name = "host";
            entities = realised-hosts;
            builders = realised-builders.system;
          }
          // fluent-build-for {
            name = "home";
            entities = realised-homes;
            builders = realised-builders.home;
          };
      };
    };
  };
}
