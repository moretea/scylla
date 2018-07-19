self: super:
let
  manveru-nur-packages = fetchTarball {
    url = "https://github.com/manveru/nur-packages/archive/master.tar.gz";
    sha256 = "0cl56w8p5gxz289ahmx2s9scw0q5bahd88s35ydggl8x8sd2yy88";
  };
  manveru-nixpkgs = fetchTarball {
    url = https://github.com/manveru/nixpkgs/archive/07eb9736f0958582411d1c866c34f24f55827801.tar.gz;
    sha256 = "00gjv74ca7hmllq2mf2y3vvfdkdn22gdb1vpxm5ypi4ysg8dvpr7";
  };
in {
  git-info = (self.callPackage "${manveru-nur-packages}/default.nix" {}).lib.git-info;
  go = super.go_1_10;
  gotools = (import manveru-nixpkgs {}).gotools;
}
