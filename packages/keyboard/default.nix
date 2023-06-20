{ nixpkgs, ... }: nixpkgs.stdenv.mkDerivation {
  builder = nixpkgs.writeScript "builder.sh" ''
    source $stdenv/setup
    mkdir -p $out/bin
    cp $src/keyboard-* $out/bin
    chmod +x $out/bin/*
  '';
  pname = "keyboard";
  src = ./.;
  version = "1.0.0";
}