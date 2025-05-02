{
  lib,
  yanc-lib,
  ...
}: let
  inherit
    (lib)
    addErrorContext
    flip
    functionArgs
    intersectAttrs
    isDerivation
    isFunction
    pipe
    reverseList
    ;

  inherit
    (lib.generators)
    toPretty
    ;

  inherit
    (yanc-lib)
    filter
    without
    ;
in rec {
  call-exact = fn: x: let
    fn-args = functionArgs fn;
    intersected-args = intersectAttrs fn-args x;
  in
    fn intersected-args;

  maybe-call = fn: let
    is-function = isFunction fn;
  in
    x:
      if is-function
      then fn x
      else fn;

  # even though nixpkgs explicity says not too ;)
  compose-all = flip pipe;
  compose-all-backward = fn-list:
    compose-all (reverseList fn-list);

  overloaded = cases: let
    expected = builtins.attrNames (without "default" (filter (_: v: v != null) cases));
    err = type: value:
      addErrorContext "while evaluating overloaded function" (throw
        ''
          unexpected argument type:
                  expected -> ${builtins.concatStringsSep ", " expected}
                  received -> ${type} (${toPretty {} value})
        '');
    overloadedFn = arg: let
      typeOf-arg =
        if (isDerivation arg)
        then "derivation" # special case; worth supporting
        else builtins.typeOf arg;
      case = cases."${typeOf-arg}" or (cases.default or (err typeOf-arg));
      fn =
        if case != null
        then case
        else (err typeOf-arg);
    in
      maybe-call fn arg;
  in
    overloadedFn;
}
