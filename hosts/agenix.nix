{ agenix, ... } : {
  age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  imports = [ agenix.nixosModules.default ];
}
