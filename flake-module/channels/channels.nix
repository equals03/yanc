{
  inputs,
  lib,
  yanc-lib,
  config,
  ...
}: let
  inherit
    (lib)
    literalExpression
    mkIf
    mkOption
    ;
  inherit
    (yanc-lib)
    filter
    is-nixpkgs
    map
    types
    ;

  cfg = config;
  cfg-settings = cfg.yanc.settings;

  channel-type = with types; (submodule ({
    name,
    config,
    ...
  }: {
    imports = [
      {
        config = {
          config = cfg-settings.channels.shared.config or {};
          overlays = cfg-settings.channels.shared.overlays or [];
        };
      }
    ];
    options = {
      name = mkOption {
        type = types.str;
        description = ''
          The name of the channel, automatically set to the attribute name of the channel in `yanc.channels`.
          This is used internally to reference the channel and should not be modified by the user.
        '';
        default = name;

        internal = true;
        readOnly = true;
      };

      config = mkOption {
        type = attrsOf raw;
        description = ''
          Configuration attributes for this channel, such as package settings or Nixpkgs options.
          These settings are applied to the Nixpkgs instance for this channel.
        '';
        example = literalExpression ''
          {
            allowUnfree = true;
            permittedInsecurePackages = [ "openssl-1.0.2" ];
          }
        '';
        default = {};
      };

      overlays = mkOption {
        type = uniqueListOf overlay;
        description = ''
          A list of Nix overlays to be applied to this channel. Overlays allow customization of packages
          by overriding or extending existing package definitions.
        '';
        example = literalExpression ''
          [
            (self: super: {
              hello = super.hello.overrideAttrs (oldAttrs: {
                name = "hello-custom";
                version = "1.666";
              });
            })
          ]
        '';
        default = [];
      };

      input = mkOption {
        type = uniq nixpkgs;
        description = ''
          The Nixpkgs input to be used for this channel. This specifies the source of the Nixpkgs
          package set for the channel, typically a flake input.
        '';
        example = literalExpression ''
          inputs.nixpkgs
        '';
      };
    };
  }));

  channels-from-inputs = let
    input-to-channel = input: {
      inherit input;
    };
    channel-inputs = filter (_: input: (is-nixpkgs input)) inputs;
    channels = map (_: input-to-channel) channel-inputs;
  in
    channels;
in {
  options = with types; {
    yanc = {
      channels = mkOption {
        type = attrsOf channel-type;
        description = ''
          A set of channels, each defining a Nixpkgs instance with specific configurations, overlays,
          and inputs. Channels can be manually defined or automatically discovered from flake inputs.
        '';
        example = literalExpression ''
          {
            stable = {
              input = inputs.nixpkgs;
              config = { allowUnfree = true; };
            };
            unstable = {
              input = inputs.nixpkgs-unstable;
              overlays = [ (self: super: { }) ];
            };
          }
        '';
        default = {};
      };
      settings.channels = {
        discover = mkOption {
          type = bool;
          description = ''
            Whether to automatically discover channels from flake inputs that are identified as Nixpkgs.
            If enabled, channels are created for each Nixpkgs input, using the input as the channel's source.
          '';
          example = literalExpression ''
            false
          '';
          default = true;
        };

        shared = mkOption {
          type = submodule {
            options = {
              config = mkOption {
                type = attrsOf raw;
                description = ''
                  Shared configuration attributes applied to all channels. These settings are merged
                  with each channel's specific configuration.
                '';
                example = literalExpression ''
                  {
                    allowUnfree = true;
                    permittedInsecurePackages = [ "python-2.7" ];
                  }
                '';
                default = {};
              };

              overlays = mkOption {
                type = uniqueListOf overlay;
                description = ''
                  A list of overlays applied to all channels. These overlays are combined with
                  channel-specific overlays to customize package sets.
                '';
                example = literalExpression ''
                  [
                    (self: super: {
                      vim = super.vim.override { extraConfig = "set number"; };
                    })
                  ]
                '';
                default = [];
              };
            };
          };
          description = ''
            Shared settings applied to all channels, including common configurations and overlays.
            These settings provide a baseline that individual channels can extend or override.
          '';
          default = {};
        };
      };
    };
  };

  config = {
    yanc.channels = mkIf (cfg-settings.channels.discover) channels-from-inputs;
  };
}
