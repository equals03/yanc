{
  lib,
  yanc-lib,
  ...
}: let
  inherit
    (lib)
    composeManyExtensions
    getValues
    id
    isFunction
    mkOptionType
    showOption
    flatten
    mkOption
    ;

  inherit
    (yanc-lib)
    flatten-tree
    is-directory
    is-nixpkgs
    is-darwin
    merge-recursive
    overloaded
    traverse-path
    ;
in {
  types =
    lib.types
    // {
      ## types
      nixpkgs = mkOptionType {
        name = "pkgs";
        descriptionClass = "noun";
        description = "Nixpkgs package set";
        check = is-nixpkgs;
      };

      darwin = mkOptionType {
        name = "pkgs";
        descriptionClass = "noun";
        description = "Darwin package set";
        check = is-darwin;
      };

      overlay = mkOptionType {
        name = "overlay";
        description = "overlay";
        descriptionClass = "noun";
        check = isFunction;
        merge = _: defs: composeManyExtensions (getValues defs);
      };

      # not using deferredModule here.
      # throwing in my own spin so that it can recusively
      # load modules from a given path
      module = let
        # attrs to module
        attrs-def-to-module = loc: value:
          if !(value ? _file)
          then {
            _file = "${showOption loc}";
            imports = [value];
          }
          else value;
        # function to module
        function-def-to-module = loc: value: {
          _file = "${showOption loc}";
          imports = [value];
        };
        # path to module
        path-def-to-module = _loc: value: let
          path-to-module = path: {
            _file = path;
            imports = [path];
          };
        in
          if is-directory value
          then map path-to-module (flatten-tree (traverse-path value))
          else path-to-module value;

        def-to-module = loc: def: let
          switch = overloaded {
            path = path-def-to-module loc;
            string = path-def-to-module loc;
            lambda = function-def-to-module loc;
            set = attrs-def-to-module loc;
            default = id;
          };
        in switch def.value;
      in
        mkOptionType {
          name = "module";
          description = "module";
          descriptionClass = "noun";
          inherit (lib.types.deferredModule) check;
          merge = loc: defs: {imports = flatten (map (def-to-module loc) defs);};
        };

      ## compound types
      deepMergedAttrsOf = elemType: (lib.types.attrsOf elemType) // {merge = _loc: defs: merge-recursive (map (d: d.value) defs);};

      uniqueListOf = elemType: let
        inherit (opt) merge;
        opt = lib.types.listOf elemType;
      in
        opt
        // {
          merge = loc: defs: lib.unique (merge loc defs);
        };

      mkRealisedOption = opts:
        mkOption ({
            type = with lib.types; lazyAttrsOf unspecified;
            readOnly = true;
            internal = true;
          }
          // opts);
    };
}
