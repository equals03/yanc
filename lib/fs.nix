{
  lib,
  yanc-lib,
  ...
}: let
  inherit
    (builtins)
    readFileType
    readDir
    ;

  inherit
    (lib)
    filter
    isPath
    listToAttrs
    mapAttrs
    readFile
    pathExists
    mapAttrsToList
    ;
  inherit
    (yanc-lib)
    first
    get-path-components
    path-is-hidden
    overloaded
    ;

  is-file-kind = kind: kind == "regular";
  is-symlink-kind = kind: kind == "symlink";
  is-directory-kind = kind: kind == "directory";
  is-unknown-kind = kind: kind == "unknown";

  to-fs-entry = parent: name: kind: let
    fn = get-path-components name;
  in {
    inherit kind parent;
    inherit (fn) name extension;

    type = "fs-entry";
    full-name = name;
    path = parent + "/${name}";

    is-dir = is-directory-kind kind;
    is-file = is-file-kind kind;
    is-symlink = is-symlink-kind kind;
    is-unknown = is-unknown-kind kind;
    is-hidden = path-is-hidden name;
  };

  only-visible-entries = entries: filter (entry: !entry.is-hidden) entries;
  only-directory-entries = entries: filter (entry: entry.is-dir) entries;
  only-file-entries = entries: filter (entry: entry.is-file) entries;
  only-nix-file-entries = entries: filter (entry: entry.is-file && entry.extension == ".nix") entries;
  only-default-nix = entries: first (filter (entry: entry.is-file && entry.name == "default" && entry.extension == ".nix") entries);
in rec {
  is-directory = path:
    pathExists path && is-directory-kind (readFileType path);

  is-file = path:
    pathExists path && is-file-kind (readFileType path);

  safe-read-directory = path: let
    tried = try-read-directory path;
  in
    tried.content;

  safe-read-file = path: let
    tried = try-read-file path;
  in
    tried.content;

  try-read-directory = path: let
    success = is-directory path;
  in {
    inherit success;
    content =
      if success
      then readDir path
      else {};
  };

  try-read-file = path: let
    success = is-file path;
  in {
    inherit success;
    content =
      if success
      then readFile path
      else "";
  };

  get-entries = path: let
    entries = safe-read-directory path;
  in
    mapAttrsToList (name: kind: (to-fs-entry path name kind)) entries;

  get-visible-entries = path: let
    entries = get-entries path;
    visible-entries = only-visible-entries entries;
  in
    visible-entries;

  get-visible-directories = path: let
    entries = get-visible-entries path;
    directories = only-directory-entries entries;
  in
    directories;

  get-visible-files = path: let
    entries = get-visible-entries path;
    files = only-file-entries entries;
  in
    files;

  get-visible-nix-files = path: let
    entries = get-visible-files path;
    files = only-nix-file-entries entries;
  in
    files;

  traverse-path = args: let
    fn = {
      path,
      op ? (entry: entry.path),
      depth ? null,
    }: let
      actual-depth =
        if (depth == null)
        then null
        else depth - 1;
      go-deeper = actual-depth == null || actual-depth > 0;

      entries = get-visible-entries path;
      default-nix = only-default-nix entries;

      files =
        if default-nix != null
        then {default = op default-nix;}
        else
          listToAttrs (map (entry: {
            inherit (entry) name;
            value = op entry;
          }) (only-nix-file-entries entries));

      directories =
        if default-nix != null
        then {}
        else let
          listing = listToAttrs (map (entry: {
            inherit (entry) name;
            value =
              if go-deeper
              then
                traverse-path {
                  inherit op;
                  inherit (entry) path;
                  depth = actual-depth;
                }
              else {};
          }) (only-directory-entries entries));
        in
          # if the listing contains the "default.nix" then treat the subdir as a
          # file entry.
          mapAttrs (_name: value:
            value.default or value)
          listing;
    in
      {} // files // directories;
  in (overloaded {
      path = args: fn {path = args;};
      string = args: fn {path = args;};
      default = fn;
    }
    args);
}
