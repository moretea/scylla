{ name, ports ? [] }:

{
  kubernetes.resources.services."${name}" = {
    apiVersion = "v1";
    kind = "Service";
    metadata.name = "${name}";
    spec.selector.app = "${name}";
    spec.ports = ports;
  };
}
