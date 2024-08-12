_: {
  nixpkgs = {
    # No overlays yet
    # overlays = [ ];
    config = {
      allowUnfree = true;
      cudaSupport = true;
    };
  };
}
