{
  lib,
  host,
  ...
}: {
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  fileSystems."/" = {device = "/dev/disk/by-label/${host.name}";};

  nixpkgs.config.allowUnfree = lib.mkDefault true;

  system.stateVersion = "25.05";
}
