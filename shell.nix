{ nixpkgs ? import (fetchGit {
  url = https://github.com/NixOS/nixpkgs;
  ref = "24429d66a3fa40ca98b50cad0c9153e80f56c4a2";
}) {} }:
with nixpkgs;
let
  crystalLib = (import ./nix/crystal2nix.nix {
    inherit stdenv lib remarshal runCommand;
  }).crystalLib;
in
mkShell {
  buildInputs = [
    mint
    crystal shards
    openssl zlib libyaml
  ];
}
