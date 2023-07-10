with builtins;
let
  paul = readFile ./keys/paul.pub;
  raspi3b = readFile ./keys/raspi3b.pub;
  yubikey = readFile ./keys/yk5nano475.pub;
  ziph = readFile ./keys/ziph.pub;
  all = [
    paul
    raspi3b
    yubikey
    ziph
  ];
in
{
  "secrets/paul-password.age".publicKeys = all;
  "secrets/proton-ovpn.age".publicKeys = all;
  "secrets/proton-txt.age".publicKeys = all;
  "secrets/raspi3b-boot-ed25519.age".publicKeys = [ raspi3b ];
  "secrets/raspi3b-boot-rsa.age".publicKeys = [ raspi3b ];
}
