import (
  fetchTarball {
    url = https://github.com/nixos/nixpkgs-channels/archive/b3af2cd9627d717820c96259a878f24687066cf1.tar.gz;
    sha256 = "090x0nywha3rwr9h8cp4yhrnc495yj6r7d392zjx0fd12dpdbyjj";
  }
) {
  config = {};
  overlays = [
    (import ./overlay.nix)
  ];
}
