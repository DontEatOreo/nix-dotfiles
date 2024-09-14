{ lib, config, ... }:
{
  options.hm.ssh.enable = lib.mkEnableOption "Enable SSH";

  config = lib.mkIf config.hm.git.enable {
    programs.ssh = {
      enable = true;
      extraConfig = ''
        Host github.com
          Hostname ssh.github.com
          Port 443
          User git
          IdentityFile ${config.sops.secrets.github_ssh.path}
      '';
    };
  };
}
