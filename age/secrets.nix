with builtins;
let
  keyDir = (readDir ./keys);
  keyNames = (filter (n: keyDir.${n} == "regular") (attrNames keyDir));
  keyPaths = (map (n: ./keys/${n}) keyNames);
  keys = map readFile keyPaths;
in
{
  "secrets/paul-password.age".publicKeys = keys;
  "secrets/proton.ovpn.age".publicKeys = keys;
  "secrets/proton.txt.age".publicKeys = keys;
  "secrets/ziph-deploy-key.age".publicKeys = keys;
}
