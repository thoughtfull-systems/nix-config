{ ... }: {
  programs.keychain = {
    agents = [ "gpg,ssh" ];
    enable = true;
    extraFlags = [ "--nogui" "--systemd" "-q" ];
    inheritType = "any-once";
    keys = [ "id_ed25519" ];
  };
}
