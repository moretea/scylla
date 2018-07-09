{ pkgs ? import ./nix/nixpkgs.nix }: with pkgs;
mkShell {
  buildInputs = [
    mint
    crystal shards
    openssl zlib libyaml
  ];
}
