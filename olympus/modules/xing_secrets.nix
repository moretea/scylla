let
  inherit (import ../../nix/nixpkgs.nix) decrypt-ejson;
in

{ name, ejsonPath }:
{
  kubernetes.resources.secrets."${name}" = {
    apiVersion = "v1";
    kind = "Secret";
    metadata.name = name;
    data = decrypt-ejson ejsonPath;
  };
}
