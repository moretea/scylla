{
  containers.scylla-postgres = {
    privateNetwork = true;
    hostAddress = "192.168.100.10";
    localAddress = "192.168.100.11";
    config = { pkgs, ...}: {
      networking.firewall.enable = false;
      services.postgresql = {
        enable = true;
        enableTCPIP = true;
        package = pkgs.postgresql100;

        extraPlugins = [
          (pkgs.timescaledb.override { postgresql = pkgs.postgresql100; })
          (pkgs.postgis.override { postgresql = pkgs.postgresql100; })
        ];
        initialScript = ./init_pg.sql;
      };
    };
  };
}
