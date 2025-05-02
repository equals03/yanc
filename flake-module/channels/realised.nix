{
  config,
  lib,
  yanc-lib,
  getRealisedSystem,
  ...
}: let
  inherit
    (lib)
    mapAttrs'
    setFunctionArgs
    ;

  inherit
    (yanc-lib)
    map
    without
    compose-all
    ;

  inherit
    (yanc-lib.types)
    mkRealisedOption
    ;

  cfg = config;

  cfg-channels = cfg.yanc.channels;
  realised-channels = cfg.yanc.realised.channels;

  sanitise-channel = without ["input" "config" "overlays"];
  to-channel = compose-all [
    (
      channel: let
        import-channel = {system, ...}:
          import channel.input {
            inherit system;
            inherit (channel) config overlays;
          };
      in
        channel
        // setFunctionArgs import-channel (builtins.functionArgs import-channel)
    )
    sanitise-channel
  ];

  channel-module-args-for = system: let
    realised = (getRealisedSystem system).channels;
    channels =
      mapAttrs' (name: value: {
        inherit value;
        name = "${name}'";
      })
      realised;
  in
    # all the channels are available via ${channel-name}'
    # and channels'.${channel-name}
    channels // {channels' = realised;};
in {
  options = {
    yanc.realised = {
      channels = mkRealisedOption {
        default = cfg-channels;
        apply = channels: (map (_: to-channel) channels);
      };
    };
  };

  config = {
    _module.args.channels = realised-channels;

    yanc.realisePerSystem = {system, ...}: {
      options = {
        channels = mkRealisedOption {
          default = realised-channels;
          apply = map (_: channel: channel {inherit system;});

          internal = true;
        };
      };
    };

    perSystem = {system, ...}: {
      _module.args = channel-module-args-for system;
    };

    perTarget = {
      _module.args.channels = realised-channels;

      perSystem = (
        {system, ...}: {
          _module.args._module.args = channel-module-args-for system;
        }
      );
    };
  };
}
