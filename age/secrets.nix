let
  keyfiles = [
    /home/paul/.ssh/id_ed25519.pub
    ./keys/yk5nano475.pub
  ] ++ (if (builtins.pathExists ./keys/bootstrap.pub)
        then
          [ ./keys/bootstrap.pub ]
        else
          []);
  keys = map builtins.readFile keyfiles;
in
{
  "secrets/paul-password.age".publicKeys = keys;
}
