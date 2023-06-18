inputs: { ... }: {
  nixpkgs.overlays = [
    (final: prev: {
      unstable = import inputs.unstable {
        config.allowUnfree = final.config.allowUnfree;
        system = final.system;
      };
    })
  ];
}
