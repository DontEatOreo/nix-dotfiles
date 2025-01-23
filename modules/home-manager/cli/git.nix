{
  pkgs,
  lib,
  config,
  ...
}:
let
  userName = "DontEatOreo";
  userEmail = "57304299+${userName}@users.noreply.github.com";
  key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPsZFHUhLSPiz0EF1Q59jzu7IS7qdn3MSEImztN4KgmN";
in
{
  options.hm.git.enable = lib.mkEnableOption "Git";

  config = lib.mkIf config.hm.git.enable {
    home.file.".gitconfig".source =
      config.lib.file.mkOutOfStoreSymlink "${config.xdg.configHome}/git/config";
    home.file.".ssh/allowed_signers".text = ''
      ${userEmail} ${key}
    '';

    programs = {
      gitui.enable = true;
      gh.enable = true;
      gh.settings.git_protocol = "ssh";
      git = {
        enable = true;
        ignores = [
          ".DS_Store"
          "Thumbs.db"
          "*.DS_Store"
          "*.swp"
        ];
        inherit userName userEmail;
        signing.signByDefault = true;
        signing.key = key;
        extraConfig = {
          gpg.format = "ssh";
          "gpg.ssh" = {
            program =
              if pkgs.stdenvNoCC.hostPlatform.isLinux then
                (lib.getExe' pkgs._1password-gui "op-ssh-sign")
              else
                "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
            allowedSignersFile = "${config.home.homeDirectory}/.ssh/allowed_signers";
          };
        };
      };
      vscode.userSettings."git.enableCommitSigning" =
        if config.programs.git.signing.signByDefault then true else false;
    };
  };
}
