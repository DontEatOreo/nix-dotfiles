{pkgs, ...}: let
  # Combined .NET SDKs
  dotnetSdks = builtins.attrValues {
    inherit (pkgs) dotnet-sdk dotnet-sdk_7 dotnet-sdk_8;
  };
in {
  environment = {
    systemPackages = builtins.attrValues {
      dotnetCorePackages = pkgs.dotnetCorePackages.combinePackages dotnetSdks;
    };
  };
}
