{ inputs, ... }: {
  nixpkgs.overlays = [
    (final: prev: {
      thoughtfull = import ../packages (inputs // {
        nixpkgs = final;
      });
    })
  ];
}
