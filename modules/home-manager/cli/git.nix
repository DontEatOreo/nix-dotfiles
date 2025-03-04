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
  format = "ssh";
in
{
  options.hm.git.enable = lib.mkEnableOption "Git";

  config = lib.mkIf config.hm.git.enable {
    home.file.".gitconfig".source =
      config.lib.file.mkOutOfStoreSymlink "${config.xdg.configHome}/git/config";
    home.file.".ssh/allowed_signers".text = ''
      ${userEmail} ${key}
    '';

    home.packages = builtins.attrValues { inherit (pkgs) watchman; };

    programs = {
      gitui.enable = true;
      gh.enable = true;
      gh.settings.git_protocol = format;
      git = {
        enable = true;
        ignores = [
          ".DS_Store"
          "Thumbs.db"
          "*.DS_Store"
          "*.swp"
        ];
        inherit userName userEmail;
        signing = {
          inherit key format;
          signByDefault = true;
          signer =
            if pkgs.stdenvNoCC.hostPlatform.isLinux then
              (lib.getExe' pkgs._1password-gui "op-ssh-sign")
            else
              "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
        };
      };
      vscode.profiles.default.userSettings."git.enableCommitSigning" =
        if config.programs.git.signing.signByDefault then true else false;
      jujutsu = {
        enable = true;
        settings = {
          core.fsmonitor = "watchman";
          core.watchman.register_snapshot_trigger = true;
          user.email = userEmail;
          user.name = userName;
          ui = {
            paginate = "auto";
            merge-editor = "vscode";
            diff.format = "git";
          };
          git = {
            sign-on-push = true;
            auto-local-bookmark = false;
            push-bookmark-prefix = "donteatoreo/push-";
            subprocess = true;
          };
          signing = {
            behavior = "drop";
            backend = "ssh";
            inherit key;
            backends.ssh.program =
              if pkgs.stdenvNoCC.hostPlatform.isLinux then
                (lib.getExe' pkgs._1password-gui "op-ssh-sign")
              else
                "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
            backends.ssh.allowed-signers = "${config.home.homeDirectory}/.ssh/allowed_signers";
          };
        };
      };
    };
  };
}
