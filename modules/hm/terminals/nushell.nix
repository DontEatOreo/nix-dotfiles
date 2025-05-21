{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (pkgs.stdenvNoCC.hostPlatform) isDarwin;

  yt-dlp-script = lib.getExe (
    pkgs.writeScriptBin "yt-dlp-script" (builtins.readFile ../../../shared/scripts/yt-dlp-script.sh)
  );
in
{

  options.hm.nushell.enable = lib.mkEnableOption "Nushell";

  config = lib.mkIf config.hm.nushell.enable {
    programs.carapace.enable = true;
    programs.nushell = {
      enable = true;
      shellAliases = {
        cd = "__zoxide_z";
        dc = "__zoxide_z";

        v = "hx";
        vi = "hx";
        vim = "hx";
        h = "hx";

        ll = "ls";
        du = "dust";

        grep = "rg";
        diff = "delta";
        cat = "open";
        open = "^open";
        sed = "sd";

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
        m4a = "${yt-dlp-script} m4a";
        "m4a-cut" = "${yt-dlp-script} m4a-cut";
        mp3 = "${yt-dlp-script} mp3";
        "mp3-cut" = "${yt-dlp-script} mp3-cut";
        mp4 = "${yt-dlp-script} mp4";
        "mp4-cut" = "${yt-dlp-script} mp4-cut";
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
            rev = "b2d512f6c67f68895a26136c6ce552281efbec6e";
            hash = "sha256-iC5Qmyn9vDr4b1BWtJkC3pl2dOam2Se51+ENvRdXlvA=";
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
        builtins.concatStringsSep "\n" sourceCommands
        + "\n"
        + ''
          def nix-build-file [
              file: string,
              args: string = "{}"
          ] {
            let prefix = "with import <nixpkgs> {}; callPackage " + (readlink -f $file)
            let suffix = " " + $args
            let expr   = $prefix + $suffix
            nix-build -E $expr
          }
        '';
    };
  };
}
