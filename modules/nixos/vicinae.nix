{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  vicinaePackage = inputs.vicinae.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  boot.kernelModules = [ "uinput" ];

  environment.systemPackages = [ vicinaePackage ];

  programs.vicinae.input-server = {
    enable = true;
    package = vicinaePackage;
  };

  systemd.user.services.vicinae = {
    description = "Vicinae launcher daemon";
    documentation = [ "https://docs.vicinae.com" ];
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    unitConfig.ConditionUser = config.local.user.name;
    serviceConfig = {
      Type = "simple";
      ExecStart = "${lib.getExe vicinaePackage} server --replace";
      Restart = "always";
      RestartSec = 60;
      KillMode = "process";
    };
  };
}
