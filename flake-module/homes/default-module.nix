{
  home,
  channels',
  config,
  lib,
  ...
} @ args: let
  is-standalone = !(builtins.elem "osConfig" (builtins.attrNames args));
  cfg = config.yanc;
in {
  imports = [
    {_module.args.is-standalone = is-standalone;}
  ];

  options = {
    yanc = {
      enable = (lib.mkEnableOption "yanc") // {default = is-standalone;};
    };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [
      (_final: prev: {channels = (prev.channels or {}) // channels';})
    ];

    home.username = lib.mkDefault home.username;
    home.homeDirectory = lib.mkDefault home.homeDirectory;

    programs.home-manager.enable = lib.mkDefault true;
  };
}
