self: super:
let
  manveru-nur-packages = fetchGit {
    url = "https://github.com/manveru/nur-packages";
  };
in {
  git-info = (self.callPackage "${manveru-nur-packages}/default.nix" {}).lib.git-info;
}
