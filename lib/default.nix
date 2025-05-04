{lib, ...} @ args: let
  inherit
    (lib)
    flip
    foldr
    ;

  import-module = flip import (args // {inherit yanc-lib;});

  yanc-lib = foldr (l: r: l // r) {} [
    (import-module ./attrs.nix)
    (import-module ./lists.nix)
    (import-module ./modules.nix)
    (import-module ./fn.nix)
    (import-module ./fs.nix)
    (import-module ./path.nix)
    (import-module ./trivial.nix)

    (import-module ./types.nix)
  ];
in
  yanc-lib
