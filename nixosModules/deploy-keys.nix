{ config, lib, ... }: let
  cfg = config.thoughtfull.deploy-keys;
in {
  options.thoughtfull.deploy-keys = lib.mkOption {
    default = {};
    description = lib.mdDoc ''
    '';
    type = lib.types.attrsOf (
      lib.types.submodule (
        { name, ... }: {
          options = {
            name = lib.mkOption {
              default = name;
              description = lib.mdDoc ''
                Name of the deploy key.  Prepended to hostname for ssh config.
              '';
              type = lib.types.str;
            };
            hostname = lib.mkOption {
              default = "github.com";
              description = lib.mdDoc ''
                Hostname combined with name in ssh config.
              '';
              type = lib.types.str;
            };
            path = lib.mkOption {
              description = ''
                Path to age file containing the private key.
              '';
              type = lib.types.path;
            };
          };
        }
      )
    );
  };
  config = {
    age.secrets = lib.mkIf (cfg != {})
      (lib.mkMerge
        (lib.mapAttrsToList
          (name: options: {
            "${name}-deploy-key".file = options.path;
          })
          cfg
        )
      );
    environment.etc = lib.mkIf (cfg != {})
      (lib.mkMerge
        (lib.mapAttrsToList
          (name: options: {
            "nixos/${name}-deploy-key".source = config.age.secrets."${name}-deploy-key".path;
          })
          cfg
        )
      );
    programs.ssh = lib.mkIf (cfg != {})
      (lib.mkMerge
        (lib.mapAttrsToList
          (name: options: {
            extraConfig = ''
              Host ${name}.${options.hostname}
              Hostname ${options.hostname}
              IdentityFile "/etc/nixos/${name}-deploy-key"
            '';
          })
          cfg
        )
      );
  };
}
