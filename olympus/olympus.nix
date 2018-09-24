let
  merge = (import <nixpkgs> {}).lib.recursiveUpdate;

  service = import ./modules/xing_service.nix {
    name = "e-recruiting-api-team-scylla";
    ports = [{ name = "http"; port = 80; }];
  };

  web = import ./modules/xing_web.nix {
    namespace = "e-recruiting-api-team";
    appName = "scylla";
    appRole = "app";
    replicas = 1;
    cpu = "100m";
    memory = "512Mi";
  };
in merge service web
