{ stdenv, lib, fetchFromGitHub, crystal, libxml2, openssl, zlib, pkgconfig, tree, stuff }:
let
  crystalPackages = lib.mapAttrs (name: src:
    stdenv.mkDerivation {
      name = lib.replaceStrings ["/"] ["-"] name;
      src = fetchFromGitHub src;
      phases = "installPhase";
      installPhase = ''cp -r $src $out'';
      passthru = { libName = name; };
    }
  ) (import ./shards.nix);

  crystalLib = stdenv.mkDerivation {
    name = "crystal-lib";
    src = lib.attrValues crystalPackages;
    libNames = lib.mapAttrsToList (k: v: [k v]) crystalPackages;
    phases = "buildPhase";
    buildPhase = ''
      mkdir -p $out
      linkup () {
        while [ "$#" -gt 0 ]; do
          ln -s $2 $out/$1
          shift; shift
        done
      }
      linkup $libNames
    '';
  };

in stdenv.mkDerivation {
  name = "scylla";
  src = fetchTarball {
    url = https://github.com/manveru/scylla/archive/testing.tar.gz;
  };

  phases = "buildPhase";

  buildInputs = [
    libxml2
    openssl
    zlib
    pkgconfig
    tree
  ];

  buildPhase = ''
    mkdir -p $out/bin tmp
    cd tmp
    cp -r $src/* .
    chmod +w -R .
    rm -rf lib
    echo ${stuff} > $out/stuff
    ln -s ${crystalLib} lib
    tree /
    ${crystal}/bin/crystal build --verbose --progress --release src/server.cr -o $out/bin/scylla
  '';
}
