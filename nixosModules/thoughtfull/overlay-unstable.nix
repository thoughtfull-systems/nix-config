unstable: { ... }: {
  nixpkgs.overlays = [
    (final: prev: {
      unstable = import unstable {
        config.allowUnfree = final.config.allowUnfree;
        system = final.system;
      };
    })
  ];
}
