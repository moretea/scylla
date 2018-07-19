{ pkgs ? import ./nix/nixpkgs.nix }: {
  meta = {
    name = "scylla";
    maintainer = "Michael Fellinger <mf@seitenschmied.at>";
  };
  scylla = pkgs.callPackage ./. {};
  docker = pkgs.callPackage ./nix/docker.nix {};
  deep = pkgs.recurseIntoAttrs {
    scylla = pkgs.callPackage ./. {};
    thisIsNotEvaluate = {
      scylla = pkgs.callPackage ./. {};
    };
  };
}
