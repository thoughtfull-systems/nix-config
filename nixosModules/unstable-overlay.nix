{ unstable, ... }: {
  nixpkgs.overlays = [
    (final: prev: {
      unstable = import unstable {
        config.allowUnfree = prev.config.allowUnfree;
        system = prev.system;
      };
    })
  ];
}
