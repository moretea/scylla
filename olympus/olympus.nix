let
  lib = (import ../nix/nixpkgs.nix).lib;
  merge = lib.fold (a: b: lib.recursiveUpdate a b) {};
  envPublic = name: value: { inherit name value; };
  envSecret = name: {
    inherit name;
    valueFrom.secretKeyRef = { name = "kubernetes-secrets"; key = name; };
  };

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
    env = [
      (envSecret "BUILDERS")
      (envSecret "DATABASE_URL")
      (envSecret "GITHUB_TOKEN")
      (envSecret "GITHUB_URL")
      (envSecret "GITHUB_USER")
      (envSecret "PRIVATE_SIGNING_KEY")
      (envSecret "PRIVATE_SSH_KEY")
      (envSecret "PUBLIC_SIGNING_KEY")
    ];
  };

  config = import ./modules/xing_config_map.nix {
    name = "scylla-config";
    data = {
      HOST = "0.0.0.0";
      PORT = "80";
    };
  };

  secrets = import ./modules/xing_secrets.nix {
    name = "kubernetes-secrets";
    ejsonPath = ./misc.production/secrets.ejson;
  };
in merge [service web config secrets]
