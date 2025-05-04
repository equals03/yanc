{
  lib,
  yanc-lib,
  ...
}: let
  inherit
    (lib)
    isAttrs
    filterAttrs
    filterAttrsRecursive
    mapAttrs
    mapAttrs'
    optionals
    optionalAttrs
    ;

  inherit
    (yanc-lib)
    overloaded
    ;

  is-flake = maybe-flake:
    (maybe-flake._type or "") == "flake";
in {
  # absolutely horrible cludge, but it "works(tm)"
  # "it'll do donkey, it'll do"
  is-nixpkgs = maybe-pkgs:
    (is-flake maybe-pkgs)
    && ((maybe-pkgs.lib or {}) ? nixpkgsVersion)
    && maybe-pkgs ? legacyPackages
    && isAttrs maybe-pkgs.legacyPackages;

  # same as above, but for darwin, relaxed though
  # because not used as a "channel" for importing
  is-darwin = maybe-pkgs:
    (is-flake maybe-pkgs)
    && ((maybe-pkgs.lib or {}) ? darwinSystem);

  # aaaannnnd, yes. same for nixos-generators
  is-nixos-generators = maybe-ng:
    (is-flake maybe-ng)
    && maybe-ng ? nixosGenerate;

  # aaaannnnd, yes. same for home-manager
  is-home-manager = maybe-hm:
    (is-flake maybe-hm)
    && ((maybe-hm.lib or {}) ? homeManagerConfiguration);

  # because life is to short to worry about filter vs filterAttrs
  filter = predicate: (overloaded {
    set = filterAttrs predicate;
    list = builtins.filter predicate;
  });

  # just wanted to keep it "in the same place"
  filter' = predicate: (overloaded {
    set = filterAttrsRecursive predicate;
  });

  # because life is to short to worry about map vs mapAttrs
  map = f: (overloaded {
    set = mapAttrs f;
    list = builtins.map f;
  });

  # just wanted to keep it "in the same place"
  map' = f: (overloaded {
    set = mapAttrs' f;
  });

  # because life is to short to worry about optional vs optionals vs optionalAttrs
  optional = cond: (overloaded {
    set = optionalAttrs cond;
    list = optionals cond;
    default = lib.optional cond;
  });

  # i do so miss w = x ? y : z;
  ternary = condition: true-value: false-value:
    if condition
    then true-value
    else false-value;

  is-null = value: value == null;
  is-not-null = value: value != null;
}
