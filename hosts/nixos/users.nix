{
  pkgs,
  username,
  config,
  ...
}:
{
  sops.secrets.nyx-password.neededForUsers = true;

  users.mutableUsers = false;

  users.users = {
    ${username} = {
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "network"
        "networkmanager"
        "audio"
      ];
      shell = pkgs.zsh;
      hashedPasswordFile = config.sops.secrets.nyx-password.path;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMG8yRBKWpJT8cqgMLtIag4M0VrOXLvhM9kqiEIwTpxj (none)"
      ];
    };
  };
}
