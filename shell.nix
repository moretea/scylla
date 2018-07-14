{ pkgs ? import ./nix/nixpkgs.nix }: with pkgs;
mkShell {
  buildInputs = [
    nix
    mint
    crystal shards
    openssl zlib libyaml
  ];
}
