with import <nix/config.nix>;
derivation {
  name = "failing";
  system = builtins.currentSystem;
  PATH = "${coreutils}";
  builder = shell;
  args = ["-c" "touch nope"];
}
