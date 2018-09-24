{ name
, deploymentID ? "123"
, tag ? "latest"
, args ? []
, namespace
, cpu ? "300m"
, memory ? "512Mi"
}:

{
  kubernetes.resources.pods."${name}-${deploymentID}" = {
    apiVersion = "v1";
    kind = "Pod";
    metadata = {
      name = "${name}-${deploymentID}";
      namespace = namespace;
    };
    spec = {
      restartPolicy = "never";
      activeDeadlineSeconds = 600;
      imagePullSecrets = [
        { name = "quay-pull-secret"; }
      ];
      containers."${name}" = {
        name = name;
        image = "quay.dc.xing.com/${namespace}/${name}:${tag}";
        args = args;
        envFrom = [
          { configMapRef.name = "shared-dynamic-config"; }
          { configMapRef.name = "${name}-config"; }
        ];
        resources = {
          requests = {
            cpu = cpu;
            memory = memory;
          };
        };
      };
    };
  };
}
