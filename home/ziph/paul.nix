{ thoughtfull, ... } : {
  imports = [
    thoughtfull.paul
    thoughtfull.syncthing
  ];
  thoughtfull.services.syncthing-init.folders = {
    org = {
      devices = [ "hemera" ];
      enable = true;
    };
    org-work = {
      devices = [ "hemera" ];
      enable = true;
    };
    sync = {
      devices = [ "hemera" ];
      enable = true;
    };
  };
}
