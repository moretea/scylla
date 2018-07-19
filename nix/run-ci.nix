{ pkgs ? import ./nixpkgs.nix
, ciNix
, pname
, stdenv ? pkgs.stdenv
, lib ? pkgs.lib }:

with builtins;

let
  ci = ciNix {};

  cond = (as:
    !(lib.isDerivation as) && # don't recurse into derivations
    (as ? recurseForDerivations && as.recurseForDerivations)
  );
  flat = lib.mapAttrsRecursiveCond cond (name: value:
    if lib.isDerivation value
    then [name value]
    else null
  ) ci;
  withoutNull = lib.filterAttrsRecursive (n: v: v != null) flat;
  listsOnly = lib.collect isList withoutNull;
  pathSet = listToAttrs (map (x:
    { name = lib.concatStringsSep "/" (elemAt x 0);
      value = elemAt x 1; }
  ) listsOnly);

  nixConfig = import <nix/config.nix>;

in derivation {
  name = pname;

  __structuredAttrs = true;

  PATH = nixConfig.coreutils;
  system = currentSystem;
  builder = nixConfig.shell;
  args = [
    "-e"
    (builtins.toFile "ci-builder.sh" ''
    source .attrs.sh
    eval "$buildCommand"
    '')
  ];

  ci = pathSet;

  buildCommand = ''
    set -ex
    out="''${outputs[out]}"
    for key in "''${!ci[@]}"; do
      mkdir -p $(dirname $out/$key)
      ln -s "''${ci[$key]}" $out/$key
    done
  '';
}
