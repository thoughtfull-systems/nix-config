nixpkgs:
nixpkgs.substituteAll {
  dir = "bin";
  isExecutable = true;
  src = ./yubikey-touch-status;
  bash = "${nixpkgs.bash}/bin/bash";
}
