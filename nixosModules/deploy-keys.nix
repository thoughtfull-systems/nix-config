{ config, lib, ... }: let
  cfg = config.thoughtfull.deploy-keys;
in {
  options.thoughtfull.deploy-keys = lib.mkOption {
    default = null;
    description = lib.mdDoc ''
    '';
    type = lib.types.attrsOf (
      lib.types.submodule (
        { name, ... }: {
          options = {
            name = lib.mkOption {
              default = name;
              description = lib.mdDoc ''
              '';
              type = lib.types.str;
            };
            hostname = lib.mkOption {
              default = null;
              description = lib.mdDoc ''
              '';
              type = lib.types.str;
            };
            path = lib.mkOption {
              type = lib.types.path;
              default = null;
              description = ''
              '';
            };
          };
        }
      )
    );
  };
  config = lib.mkIf (cfg != {})
    lib.mkMerge
    (lib.mapAttrsToList
      (name: cfg: {
        age.secrets."${name}-deploy-key".file = cfg.path;
        environment.etc."${name}-deploy-key".source = config.age.secrets."${name}-deploy-key".path;
        programs.ssh.extraConfig = ''
          Host ${name}.${cfg.hostname}
          Hostname ${cfg.hostname}
          IdentityFile "/etc/nixos/${name}-deploy-key"
        '';
      })
      cfg);
}
