with (import (fetchGit {
  url = https://github.com/NixOS/nixpkgs;
  ref = "24429d66a3fa40ca98b50cad0c9153e80f56c4a2";
}) {});
{
  server-static = callPackage ./. {};
}
