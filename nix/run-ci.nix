{ pkgs ? import ./nixpkgs.nix
, ciNix
, url
, sha
, stdenv ? pkgs.stdenv
, lib ? pkgs.lib }:
let
  ci = ciNix {};

  drvs = lib.filterAttrsRecursive (k: v:
    (lib.isDerivation (builtins.trace v v )) || (v.recurseForDerivations or false))
    ci;

  outPaths = lib.mapAttrs (k: v: "${v}") drvs;

  results = pkgs.writeText "results.json" (builtins.toJSON outPaths);

  # { recurseForDerivations = true; }
  # {scylla = <drv>; docker = <drv>; foobar = { x = "hi"; };}
in stdenv.mkDerivation {
  # result = builtins.trace results results;
  buildInputs = [ pkgs.jq ];
  phases = ["buildPhase"];

  inherit results;

  buildPhase = ''
    set -ex
    mkdir -p $out

    jq . < $results
    ln -s $result $out/result
    echo '${url}' > $out/url
    echo '${sha}' > $out/sha
  '';
}
