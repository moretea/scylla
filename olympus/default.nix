{ pkgs ? import <nixpkgs> {} }:
let
  kubenix = import (pkgs.fetchFromGitHub {
    owner = "xtruder";
    repo = "kubenix";
    rev = "7287c4ed9ee833ccbce2185038c068bac9c77e7c";
    sha256 = "1f69h31nfpifa6zmgrxiq72cchb6xmrcsy68ig9n8pmrwdag1lgq";
  }) { inherit pkgs; };
in
  kubenix.buildResources { configuration = ./olympus.nix; }
