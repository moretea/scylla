import (fetchGit {
  url = https://github.com/NixOS/nixpkgs;
  ref = "master";
}) {
  config = {};
  overlays = [
    (import ./overlay.nix)
  ];
}
