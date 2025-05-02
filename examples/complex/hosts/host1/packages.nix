{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    channels.nixpkgs-unstable.fzf
    bat
  ];
}
