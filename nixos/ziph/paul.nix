{ config, thoughtfull, ... }: {
  age.secrets.paul-password.file = ../../age/secrets/paul-password.age;
  home-manager.users.paul.imports = [ ../../home/ziph/paul.nix ];
  imports = [ thoughtfull.paul ];
  users.users.paul.passwordFile = config.age.secrets.paul-password.path;
}
