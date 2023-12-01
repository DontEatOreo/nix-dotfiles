{pkgs, ...}: {
  users.users = {
    nyx = {
      isNormalUser = true;
      extraGroups = ["wheel" "networkmanager" "audio"];
      shell = pkgs.zsh;
    };
  };
}
