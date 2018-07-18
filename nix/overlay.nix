self: super:
let
  manveru-nur-packages = fetchTarball {
    url = "https://github.com/manveru/nur-packages/archive/master.tar.gz";
    sha256 = "0cl56w8p5gxz289ahmx2s9scw0q5bahd88s35ydggl8x8sd2yy88";
  };
in {
  git-info = (self.callPackage "${manveru-nur-packages}/default.nix" {}).lib.git-info;
}
