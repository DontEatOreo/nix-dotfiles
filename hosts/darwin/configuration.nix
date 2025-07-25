{
  inputs,
  pkgs,
  pkgsUnstable,
  config,
  ...
}:
{
  imports = [ inputs.sops-nix.darwinModules.sops ];

  system.primaryUser = "anon";

  nixpkgs.hostPlatform.system = "aarch64-darwin";

  users.users.anon = {
    name = "anon";
    home = "/Users/anon";
    shell = pkgs.zsh;
  };

  nixOS.lix.enable = true;

  launchd.user.agents."symlink-zsh-config" = {
    script = ''
      ln -sfn "/etc/zprofile" "/Users/${config.system.primaryUser}/.zprofile"
      ln -sfn "/etc/zshenv" "/Users/${config.system.primaryUser}/.zshenv"
      ln -sfn "/etc/zshrc" "/Users/${config.system.primaryUser}/.zshrc"
    '';
    serviceConfig.RunAtLoad = true;
    serviceConfig.StartInterval = 0;
  };

  services.tailscale.enable = true;
  services.tailscale.package = pkgsUnstable.tailscale;

  sops = {
    age.keyFile = "/Users/anon/Library/Application Support/sops/age/keys.txt";
    defaultSopsFile = ../../secrets/secrets.yaml;
    secrets.github_ssh = { };
    secrets.lenovo_legion_5_15arh05h_ssh = { };
  };
}
