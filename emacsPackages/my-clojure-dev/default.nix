epkgs: {
  my-clojure-dev = epkgs.elpaBuild {
    packageRequires = with epkgs; [
      cider
      clojure-mode
      clojure-mode-extra-font-locking
      flycheck-clj-kondo
      flycheck-clojure
    ];
    pname = "my-clojure-dev";
    src = ./my-clojure-dev.el;
    version = "0.0.0";
  };
}
