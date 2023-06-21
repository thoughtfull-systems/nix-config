{ nixpkgs, ... }: let
  setxkbmap = "${nixpkgs.xorg.setxkbmap}/bin/setxkbmap";
in nixpkgs.symlinkJoin {
  name = "keyboard";
  paths = [
    (nixpkgs.substituteAll {
      dir = "bin";
      isExecutable = true;
      src = ./keyboard-status;
      inherit setxkbmap;
    })
    (nixpkgs.substituteAll {
      dir = "bin";
      isExecutable = true;
      src = ./keyboard-toggle;
      inherit setxkbmap;
    })
  ];
}
