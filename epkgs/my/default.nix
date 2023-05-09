unstable: self: super: {
  my = self.elpaBuild {
    packageRequires = with self; [
      all-the-icons
      all-the-icons-completion
      all-the-icons-ibuffer
      nix-mode
      use-package
    ] ++ (with unstable.emacs28Packages; [
      # an abandoned and resurrected project; the alignment is off on the
      # release version, but better on unstable
      all-the-icons-dired
    ]);
    pname = "my";
    src = ./my.el;
    version = "0.0.0";
  };
}
