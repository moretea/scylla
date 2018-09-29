with builtins;

let
  lib = (import ../nix/nixpkgs.nix).lib;
  merge = lib.fold (a: b: lib.recursiveUpdate a b) {};
  envPublic = name: value: { inherit name value; };
  envSecret = name: {
    inherit name;
    valueFrom.secretKeyRef = { name = "kubernetes-secrets"; key = name; };
  };
  ejsonPath = ./misc.production/secrets.ejson;
  encryptedSecrets = fromJSON (readFile ejsonPath);
  encryptedSecretKeys = attrNames encryptedSecrets.kubernetes_secrets.credentials.data;
in merge [
  (import ./modules/xing_service.nix {
    name = "e-recruiting-api-team-scylla";
    ports = [{ name = "http"; port = 80; }];
  })

  (import ./modules/xing_web.nix {
    namespace = "e-recruiting-api-team";
    appName = "scylla";
    appRole = "app";
    name = "e-recruiting-api-team-scylla";
    replicas = 1;
    cpu = "100m";
    memory = "512Mi";
    env = map (key: envSecret key) encryptedSecretKeys;
  })

  (import ./modules/xing_config_map.nix {
    name = "scylla-config";
    data = {
      HOST = "0.0.0.0";
      PORT = "80";
    };
  })

  (import ./modules/xing_secrets.nix {
    name = "kubernetes-secrets";
    ejsonPath = ejsonPath;
  })
]
