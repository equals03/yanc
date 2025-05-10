{
  self,
  host,
  channels',
  config,
  lib,
  ...
}: let
  cfg = config.yanc;
in {
  options = {
    yanc = {
      enable = (lib.mkEnableOption "yanc") // {default = true;};
    };
  };
  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [
      (_final: prev: {channels = (prev.channels or {}) // channels';})
    ];

    networking.hostName = lib.mkDefault host.name;
    nixpkgs = {
      hostPlatform = lib.mkDefault host.system;
    };

    system.configurationRevision = lib.mkDefault (self.shortRev or self.dirtyShortRev or self.lastModified or "unknown");
  };
}
