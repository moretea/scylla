let
  lib = (import ../nix/nixpkgs.nix).lib;
  merge = lib.fold (a: b: lib.recursiveUpdate a b) {};

  service = import ./modules/xing_service.nix {
    name = "e-recruiting-api-team-scylla";
    ports = [{ name = "http"; port = 80; }];
  };

  web = import ./modules/xing_web.nix {
    namespace = "e-recruiting-api-team";
    appName = "scylla";
    appRole = "app";
    name = "e-recruiting-api-team-scylla";
    replicas = 1;
    cpu = "100m";
    memory = "512Mi";
  };

  config = import ./modules/xing_config_map.nix {
    name = "scylla-config";
    data = {
      GITHUB_USER = "michael-fellinger";
      GITHUB_TOKEN = "da352b7ffa3400f66690f4100d2f203d39017a0c";
    };
  };
in merge [service web config]
