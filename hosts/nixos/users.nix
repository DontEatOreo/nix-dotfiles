{ pkgs, username, ... }:
{
  users.users = {
    ${username} = {
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "networkmanager"
        "audio"
      ];
      shell = pkgs.zsh;
    };
  };
}
