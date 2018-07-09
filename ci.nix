{ pkgs ? import ./nix/nixpkgs.nix }: with pkgs; {
  server-static = callPackage ./. {};
  server-test = callPackage ./. { test = true; };
  scylla = {
    otherStuff = callPackage ./. { unknown = true; };
  };
}
