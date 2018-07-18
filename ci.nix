{ pkgs ? import ./nix/nixpkgs.nix }: {
  scylla = pkgs.callPackage ./. {};
  docker = pkgs.callPackage ./nix/docker.nix {};
}
