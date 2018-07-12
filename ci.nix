{ pkgs ? import ./nix/nixpkgs.nix }: with pkgs; {
  scylla = callPackage ./. {};
  test = callPackage ./. { test = true; };
}
