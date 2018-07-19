{ pkgs ? import ./nix/nixpkgs.nix }: {
  scylla = pkgs.callPackage ./. {};
  deep = pkgs.recurseIntoAttrs {
    scylla = pkgs.callPackage ./. {};
    thisIsNotEvaluate = {
     scylla = pkgs.callPackage ./. {};
    };
  };
  docker = pkgs.callPackage ./nix/docker.nix {};
}
