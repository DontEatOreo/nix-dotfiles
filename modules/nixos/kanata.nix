{ dotfilesPackages, ... }:
{
  services.kanata = {
    enable = true;
    package = dotfilesPackages.kanata-with-cmd;
    keyboards.main = {
      configFile = builtins.path {
        path = ../../packages/kanata/kanata.kbd;
        name = "kanata-config";
      };
    };
  };
}
