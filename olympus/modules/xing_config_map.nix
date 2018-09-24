{ name, data ? {} }:

{
  kubernetes.resources.configMaps."${name}" = {
    metadata.name = name;
    metadata.labels.app = name;
    data = data;
  };
}
