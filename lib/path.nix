{
  lib,
  yanc-lib,
  ...
}: let
  inherit
    (lib)
    elem
    head
    length
    match
    substring
    ;
  inherit
    (yanc-lib)
    last
    ;
in {
  path-is-hidden = file-name: let
    hidden-prefix = ["." "_"];
  in
    elem (substring 0 1 (baseNameOf file-name)) hidden-prefix;

  get-path-components = path: let
    basename = path;
    m = match "(.*)\\.(.*)$" basename;
    len =
      if m == null
      then 0
      else length m;
    name =
      if len == 0
      then basename
      else if len > 0
      then head m
      else null;
    has-name = name != "";
  in
    if !has-name
    then {
      name = basename;
      extension = null;
    }
    else {
      inherit name;
      extension =
        if len > 1
        then ".${last m}"
        else null;
    };
}
