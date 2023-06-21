{ agenix, nixpkgs, ... }:
with nixpkgs;
stdenv.mkDerivation {
  # runtime dependencies
  buildInputs = [
    glibc
    gcc-unwrapped
    zlib
  ];
  # build dependencies
  nativeBuildInputs = [
    agenix.packages.${system}.default
    autoPatchelfHook # Automatically setup the loader, and do the magic
    dpkg
  ];
  installPhase = ''
    agenix -i /etc/ssh/ssh_host_ed25519_key -d $src > "${src}.decrypt"
    mkdir -p $out
    dpkg -x "${src}.decrypt" $out
  '';
  meta = with stdenv.lib; {
    description = "Kolide";
    platforms = [ "x86_64-linux" ];
  };
  pname = "kolide";
  src = ../../age/secrets/kolide.deb.age;
  system = "x86_64-linux";
  unpackPhase = "true";
  version = "0.0.0";
}
