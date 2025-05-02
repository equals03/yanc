{
  config,
  yanc-lib,
  ...
}: let
  inherit
    (yanc-lib)
    map
    compose-all
    ;

  inherit
    (yanc-lib.types)
    mkRealisedOption
    ;

  cfg = config;
  cfg-builders = cfg.yanc.builders;
  realised-builders = cfg.yanc.realised.builders;

  to-builder = compose-all [
    # i have literally ALWAYS wanted to write such an abomination ;)
    (builder: builder.builder builder)
  ];
in {
  options = {
    yanc.realised = {
      builders = mkRealisedOption {
        default = cfg-builders;
        apply = map (_: to-builder);
      };
    };
  };

  config = {
    _module.args.builders = realised-builders;

    yanc.realisePerSystem = {system, ...}: {
      options = {
        builders = mkRealisedOption {
          default = realised-builders;

          internal = true;
        };
      };
    };

    perSystem = {
      _module.args.builders = realised-builders;
    };

    perTarget = {
      _module.args.builders = realised-builders;
    };
  };
}
