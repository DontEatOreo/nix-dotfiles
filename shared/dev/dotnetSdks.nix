{pkgs, ...}: let
  # Combined .NET SDKs
  dotnetSdks = with pkgs; [
    dotnet-sdk # Latest LTS release (6.0)
    dotnet-sdk_7 # .NET SDK version 7
    dotnet-sdk_8 # .NET SDK version 8
  ];
in {
  environment = {
    systemPackages = with pkgs; [
      (dotnetCorePackages.combinePackages dotnetSdks)
    ];
  };
}
