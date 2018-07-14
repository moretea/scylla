{ pkgs ? import ./nix/nixpkgs.nix }: {
  scylla = pkgs.callPackage ./. { stuff = "nope"; };
  docker = pkgs.callPackage ./nix/docker.nix {};
}
