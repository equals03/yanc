{
  pkgs,
  lib,
  ...
}: {
  nixpkgs.config.allowUnfree = lib.mkDefault true;

  environment.systemPackages = with pkgs; [
    channels.nixpkgs-unstable.fzf
    bat
  ];

  system.stateVersion = "25.05";
}
