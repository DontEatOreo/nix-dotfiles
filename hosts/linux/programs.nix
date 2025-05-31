_: {
  programs = {
    steam.enable = false;
    zsh.enable = true;
    _1password.enable = true;
    _1password-gui = {
      enable = true;
      polkitPolicyOwners = [ "anon" ];
    };
  };
}
