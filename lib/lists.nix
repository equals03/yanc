{lib, ...}: let
  inherit
    (lib)
    flatten
    elemAt
    isList
    length
    ;
in {
  inherit flatten;

  first = list: let
    len = length list;
  in
    if (len <= 0)
    then null
    else elemAt list 0;

  last = list: let
    index = length list - 1;
  in
    if (index < 0)
    then null
    else elemAt list index;

  as-list = x:
    if isList x
    then x
    else [x];
}
