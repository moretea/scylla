{ pkgs ? import ./nix/nixpkgs.nix }: with pkgs;
let goDeps = callPackage ./. { runTests = false; };
in mkShell {
  buildInputs = [
    nix
    mint

    dep2nix
    gotools
    goDeps.go
    nix-prefetch-git
  ];
}
