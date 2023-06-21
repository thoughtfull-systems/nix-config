with builtins;
{
  "secrets/kolide.deb.age".publicKeys = map readFile [
    ./keys/bennu.pub
    ./keys/id_ed25519.pub
    ./keys/yk5nano475.pub
  ];
  "secrets/paul-password.age".publicKeys = map readFile [
    ./keys/yk5nano475.pub
    ./keys/id_ed25519.pub
    ./keys/ziph.pub
  ];
  "secrets/proton-ovpn.age".publicKeys = map readFile [
    ./keys/yk5nano475.pub
    ./keys/id_ed25519.pub
    ./keys/ziph.pub
  ];
  "secrets/proton-txt.age".publicKeys = map readFile [
    ./keys/yk5nano475.pub
    ./keys/id_ed25519.pub
    ./keys/ziph.pub
  ];
  "secrets/ziph-deploy-key.age".publicKeys = map readFile [
    ./keys/yk5nano475.pub
    ./keys/id_ed25519.pub
    ./keys/ziph.pub
  ];
}
