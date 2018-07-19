{ pkgs ? import ./nixpkgs.nix
, ciNix
, url
, sha
, stdenv ? pkgs.stdenv
, lib ? pkgs.lib }:

with builtins;

let
  ci = ciNix {};
  flat = lib.mapAttrsRecursiveCond (as:
    !(lib.isDerivation as) && # don't recurse into derivations
    (as ? recurseForDerivations && as.recurseForDerivations)
  ) (name: value:
    if lib.isDerivation value
    then [name value]
    else null
  ) ci;

  clean = lib.filterAttrsRecursive (n: v: v != null) flat;
  lists = lib.collect isList clean;
  pathSet = listToAttrs (map (x:
    { name = lib.concatStringsSep "/" (elemAt x 0);
      value = elemAt x 1; }
  ) lists);

  nixConfig = import <nix/config.nix>;
in derivation {
  name = "run-ci";

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

    cat .attrs.sh

    out="''${outputs[out]}"

    for key in "''${!ci[@]}"; do
      mkdir -p $(dirname $out/$key)
      ln -s "''${ci[$key]}" $out/$key
    done
  '';
}
