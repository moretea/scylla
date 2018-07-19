with import <nix/config.nix>;
derivation {
  name = "passing";
  system = builtins.currentSystem;
  deps = chrootDeps;
  PATH = "${coreutils}";
  builder = shell;
  args = ["-c" "touch $out"];
}
