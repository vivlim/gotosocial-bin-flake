flake: { config, lib, pkgs, ... }:
let
  inherit (lib) types mkEnableOption mkOption;
  cfg = config.services.gotosocial;
in
{
  options = {
    services.gotosocial = {
      enable = mkEnableOption ''
        GoToSocial
      '';

      config = mkOption {
        type = types.attrs ;
        default = null;
        description = ''
          Configuration attribute set. Converted to yaml.
        '';
      };
      dataDir = mkOption {
        type = types.path;
        default = "/var/lib/gotosocial";
        description = ''
          Path gotosocial will run in.
        '';
      };

      webAssetDir = mkOption {
        type = types.path;
        default = "${cfg.package}/web";
        description = ''
          Where to load web assets from.
        '';
      };

      port = mkOption {
        type = types.int;
        default = 443;
        description = ''
          HTTP(S) listen port.
        '';
      };

      host = mkOption {
        type = types.str;
        default = "localhost";
        description = ''
          Hostname of the server.
        '';
      };

      package = mkOption {
        type = types.package;
        default = flake.packages.x86_64-linux.default;
        description = ''
          The gotosocial package to run.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable (let
    configFile = (lib.generators.toYAML {} ({
      host = cfg.host;
      port = cfg.port;
      db-type = "sqlite";
      db-address = "gotosocial.db";
      storage-local-base-path = "${cfg.dataDir}/storage/";
      letsencrypt-cert-dir = "${cfg.dataDir}/certs/";
      web-template-base-dir = "${cfg.webAssetDir}/template/";
      web-asset-base-dir = "${cfg.webAssetDir}/assets/";
    } // cfg.config));
  in {
    users.users.gotosocial = {
      description = "gotosocial daemon user";
      isSystemUser = true;
      group = "gotosocial";
    };

    environment.etc."gotosocial.yaml".text = configFile;
    environment.systemPackages = [
      cfg.package
    ];

    users.groups.gotosocial = {};

    systemd.services.gotosocial = {
      description = "gotosocial webservice";
      after = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        User = "gotosocial";
        Group = "gotosocial";
        Restart = "on-failure";
        ExecStart = "${cfg.package}/bin/gotosocial --config-path /etc/gotosocial.yaml server start";
        WorkingDirectory = "${cfg.dataDir}";
      };

      environment = {
      };

    };
    systemd.tmpfiles.rules = [
      "d '${cfg.dataDir}' 0750 gotosocial gotosocial - -"
    ];
  });
}
