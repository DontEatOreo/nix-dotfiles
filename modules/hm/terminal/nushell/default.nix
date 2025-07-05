{
  pkgs,
  pkgsUnstable,
  lib,
  config,
  ...
}:
let
  inherit (pkgs.stdenvNoCC.hostPlatform) isDarwin;
in
{

  options.hm.nushell.enable = lib.mkEnableOption "Nushell";

  config = lib.mkIf config.hm.nushell.enable {
    programs.carapace.enable = true;
    programs.nushell = {
      enable = true;
      package = pkgsUnstable.nushell;
      shellAliases = {
        cd = "__zoxide_z";
        dc = "__zoxide_z";

        v = "hx";
        vi = "hx";
        vim = "hx";
        h = "hx";

        ll = "ls";
        du = "dust";

        cat = "open";
        open = "^open";

        htop = "btop";
        neofetch = "fastfetch";

        update = "nix flake update --flake (readlink -f /etc/nixos/)";
        check =
          if isDarwin then
            "sudo darwin-rebuild check --flake (readlink -f /etc/nixos/)"
          else
            "nix flake check (readlink -f /etc/nixos/)";
        rebuild =
          if isDarwin then
            "sudo darwin-rebuild switch --flake (readlink -f /etc/nixos/)"
          else
            "nixos-rebuild switch --use-remote-sudo --flake (readlink -f /etc/nixos/)";

        # Video
        m4a = "${lib.getExe pkgs.yt-dlp-script} m4a";
        "m4a-cut" = "${lib.getExe pkgs.yt-dlp-script} m4a-cut";
        mp3 = "${lib.getExe pkgs.yt-dlp-script} mp3";
        "mp3-cut" = "${lib.getExe pkgs.yt-dlp-script} mp3-cut";
        mp4 = "${lib.getExe pkgs.yt-dlp-script} mp4";
        "mp4-cut" = "${lib.getExe pkgs.yt-dlp-script} mp4-cut";
      } // lib.optionalAttrs isDarwin { micfix = "sudo killall coreaudiod"; };

      configFile.text = ''
        # Generic
        $env.EDITOR = "hx";
        $env.VISUAL = "hx";
        $env.config.show_banner = false;
        $env.config.buffer_editor = "hx";

        # Vi
        $env.config.edit_mode = "vi";
        $env.config.cursor_shape.vi_insert = "line"
        $env.config.cursor_shape.vi_normal = "block"

        let $config = {
          rm_always_trash: true
          shell_integration: true
          highlight_resolved_externals: true
          use_kitty_protocol: true
          completion_algorithm: "fuzzy"
        }
      '';

      extraConfig =
        let
          customCompletions = pkgs.fetchFromGitHub {
            owner = "nushell";
            repo = "nu_scripts";
            rev = "f0cd46cafc9d0d73efde0f2a0b6f455dd2dfbfe3";
            hash = "sha256-JEytcntdN+krsjzJdwa+pbF76Z2XhStdKS9/GZ9JjtE=";
          };
          completionTypes = [
            "bat"
            "curl"
            "git"
            "man"
            "nix"
            "rg"
            "ssh"
            "vscode"
            "zellij"
          ];
          sourceCommands = map (
            t: "source ${customCompletions}/custom-completions/${t}/${t}-completions.nu"
          ) completionTypes;
        in
        builtins.concatStringsSep "\n" sourceCommands + "\n" + builtins.readFile ./aliases.nu;
    };
  };
}
