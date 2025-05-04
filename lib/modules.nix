{lib, ...}: let
  inherit
    (lib)
    mkOverride
    ;
in {
  # mkDefault = mkOverride 1000; # used in config sections of non-user modules to set a default
  # mkImageMediaOverride = mkOverride 60; # image media profiles can be derived by inclusion into host config, hence needing to override host config, but do allow user to mkForce
  # mkForce = mkOverride 50;
  # mkVMOverride = mkOverride 10; # used by ‘nixos-rebuild build-vm’

  # I need something between mkDefault and mkForce for my personal preferences.
  # this way I can create base modules that respect my preferred value but do not clash
  # with any other modules.
  mkPreferred = mkOverride 194; # seems reasonable :P
}
