{
  lib,
  yanc-lib,
  ...
}: let
  inherit
    (lib)
    all
    attrValues
    concatLists
    filterAttrs
    foldl'
    flip
    head
    isAttrs
    isList
    last
    mapAttrs
    tail
    unique
    zipAttrsWith
    attrNames
    flatten
    ;

  inherit
    (yanc-lib)
    compose-all
    as-list
    ;
in rec {
  /*
  merge-recursive

  Recursively merges a list of attribute sets into a single attribute set. Values are combined as follows:
  - Single value: Used as-is.
  - Lists: Concatenated and deduplicated.
  - Attribute sets: Recursively merged.
  - Other types: Last value is used.

  # Arguments

  - [attrs]: List of attribute sets to merge from left to right.

  # Type

  ```
  merge-recursive :: [AttrSet] -> AttrSet
  ```

  # Example

  ```nix
  merge-recursive [
    { a = { x = 1; y = [1 2]; }; b = [1 2]; c = "first"; }
    { a = { y = [2 3]; z = true; }; b = [3 4]; c = "second"; }
  ]
  => { a = { x = 1; y = [1 2 3]; z = true; }; b = [1 2 3 4]; c = "second"; }
  ```
  */
  merge-recursive = let
    f = attr-path:
      zipAttrsWith (
        n: values:
          if tail values == []
          then head values
          else if all isList values
          then unique (concatLists values)
          else if all isAttrs values
          then f (attr-path ++ [n]) values
          else last values
      );
  in
    f [];

  concat-map = f: v:
    foldl' (x: y: merge-recursive [x y]) {}
    (attrValues (mapAttrs f v));

  ## concat-map with filtering
  concat-map' = pred: map:
    compose-all [
      (filterAttrs pred) # filter
      (concat-map map) # map
    ];

  flatten-tree = tree: let
    should-recurse = val: (isAttrs val) && !((val ? type && (val.type == "derivation" || val.type == "fs-entry")) || val ? _file);
    op = sum: val:
      if (should-recurse val)
      then (recurse sum val)
      else (sum ++ flatten val);

    recurse = sum: val:
      foldl'
      (sum: key: op sum val.${key})
      sum
      (attrNames val);
  in
    if (should-recurse tree)
    then recurse [] tree
    else flatten tree;

  without = compose-all [
    as-list
    (flip removeAttrs)
  ];

  groupByAttrs = attr-name: attrs: let
    names = builtins.attrNames attrs;
    grouped =
      builtins.foldl' (
        acc: name: let
          value = attrs.${name};
          group-key = value.${attr-name};
        in
          acc
          // {
            ${group-key} =
              (acc.${group-key} or {})
              // {
                ${name} = value;
              };
          }
      ) {}
      names;
  in
    grouped;

  groupByAttrs' = key-selector: attrs: let
    names = builtins.attrNames attrs;
    grouped =
      builtins.foldl' (
        acc: name: let
          value = attrs.${name};
          group-key = key-selector value;
        in
          acc
          // {
            ${group-key} =
              (acc.${group-key} or {})
              // {
                ${name} = value;
              };
          }
      ) {}
      names;
  in
    grouped;
}
