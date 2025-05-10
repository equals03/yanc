{
  config,
  yanc-lib,
  ...
}: let
  inherit
    (yanc-lib)
    compose-all
    groupByAttrs'
    map
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
        apply = builders: (map (_: type: map (_: to-builder) type) (groupByAttrs' (b: b.type) builders));
      };
    };
  };

  config = {
    _module.args = {
      builders = realised-builders;
    };

    yanc.realisePerSystem = _: {
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
  };
}
