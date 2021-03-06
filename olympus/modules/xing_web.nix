let
  inherit (import ../../nix/nixpkgs.nix) makeDeploymentID tagFromGit busybox coreutils;
in

{ appName
, appRole
, name ? "${appName}-${appRole}"
, namespace
, replicas
, args ? []
, env ? []
, deploymentID ? makeDeploymentID tag
, logjamName ? appName
, tag ? tagFromGit ./../..
, cpu
, memory
}:

{
  kubernetes.resources.deployments."${name}" = {
    apiVersion = "apps/v1beta2";
    kind = "Deployment";
    metadata = {
      name = name;
      namespace = namespace;
      annotations."com.xing.dynamic-config" = "enabled";
    };
    spec = {
      revisionHistoryLimit = 5;
      replicas = replicas;
      selector = {
        matchLabels = {
          app = name;
          appName = appName;
          appRole = appRole;
        };
      };
      # nginx-ingress-controller config update interval is 3 seconds
      minReadySeconds = 4;
      strategy = {
        rollingUpdate = {
          maxUnavailable = if replicas == 1 then 0 else 1;
          maxSurge = "25%";
        };
        type = "RollingUpdate";
      };
      template = {
        metadata = {
          labels = {
            app = name;
            appName = appName;
            appRole = appRole;
          };
          annotations = {
            "com.xing.ci-deployment.timestamp" = deploymentID;
            "com.xing.logjam.app.name" = logjamName;
            "com.xing.monitoring.scrape" = "true";
          };
        };
        spec = {
          terminationGracePeriodSeconds = 60;
          imagePullSecrets = [
            { name = "quay-pull-secret"; }
          ];
          containers."${name}" = {
            name = name;
            image = "quay.dc.xing.com/${namespace}/${appName}:${tag}";
            args = args;
            ports = [
              { containerPort = 80; }
              { containerPort = 10254; }
            ];
            envFrom = [
              { configMapRef.name = "shared-dynamic-config"; }
              { configMapRef.name = "${appName}-config"; }
            ];
            env = env;
            resources = {
              requests = {
                cpu = cpu;
                memory = memory;
              };
            };
            livenessProbe = {
              httpGet = {
                path = "/_system/alive";
                port = 80;
              };
              failureThreshold = 5;
              initialDelaySeconds = 5;
              periodSeconds = 5;
              timeoutSeconds = 1;
            };
            readinessProbe = {
              # Make sure the port match the one define in the livenessProbe (default curl port is 80)
              exec.command = [
                "${busybox}/bin/sh" "-c" ''test "$(curl -s localhost/_system/alive)" = "ALIVE"''
              ];
              failureThreshold = 1;
              initialDelaySeconds = 5;
              periodSeconds = 1;
            };
            lifecycle = {
              postStart.exec.command = [
                "${busybox}/bin/sh" "-c" "mkdir -p /virtual/lb_check/ && echo ALIVE > /virtual/lb_check/alive.txt"
              ];
              # sleep >3s is necessary to let nginx ingress controller remove the endpoint
              preStop.exec.command = ["${coreutils}/bin/sleep" "4"];
            };
          };
        };
      };
    };
  };
}
