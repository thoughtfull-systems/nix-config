let
  yk5nano475 = "age1yubikey1qdlg5tuvtwc7kl8k75a98wwc09l8ysywr7gsamxk8spgs08s4tjcxd4eytg";
  ssh = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK4ztYeWkCSPNWnSxiqxx49qeP1uzibyj15rRCWgoLJb paul@hemera.stadig.name";
  users = [ yk5nano475 ];

  # system1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPJDyIr/FSz1cJdcoW69R+NrWzwGK/+3gJpqD1t8L2zE";
  # system2 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKzxQgondgEYcLpcPdJLrTdNgZ2gznOHCAxMdaceTUT1";
  # systems = [ system1 system2 ];
in
{
  "paul-password.age".publicKeys = [ yk5nano475 ssh ];
}
