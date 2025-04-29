{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (pkgs.stdenvNoCC.hostPlatform) isDarwin;

  nixConfigPath = if isDarwin then "${config.home.homeDirectory}/.nixpkgs" else "/etc/nixos";

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
      shellAliases =
        lib.mkForce {
          # Directories
          cd = "z";
          dc = "zi";

          # Editors
          v = "hx";
          vi = "hx";
          vim = "hx";
          h = "hx";

          # Operations
          ll = "ls";
          du = "dust";

          # Text Processing
          grep = "rg";
          diff = "delta";
          cat = "open";
          open = "^open";
          sed = "sd";

          # Programs
          htop = "btop";
          neofetch = "fastfetch";

          # Nix
          update = "nix flake update --flake ${nixConfigPath}";
          check =
            if isDarwin then
              "darwin-rebuild check --flake ${nixConfigPath}"
            else
              "nix flake check ${nixConfigPath}";
          rebuild =
            if isDarwin then
              "darwin-rebuild switch --flake ${nixConfigPath}"
            else
              "nixos-rebuild switch --use-remote-sudo --flake ${nixConfigPath}";

          # Video
          m4a = "${yt-dlp-script} m4a";
          "m4a-cut" = "${yt-dlp-script} m4a-cut";
          mp3 = "${yt-dlp-script} mp3";
          "mp3-cut" = "${yt-dlp-script} mp3-cut";
          mp4 = "${yt-dlp-script} mp4";
          "mp4-cut" = "${yt-dlp-script} mp4-cut";
        }
        // lib.optionalAttrs isDarwin { micfix = "sudo killall coreaudiod"; };

      plugins = builtins.attrValues {
        inherit (pkgs.nushellPlugins)
          formats
          highlight
          query
          # units
          ;
      };

      envFile.text = lib.optionalString (config.programs.starship.enable) ''
        $env.TRANSIENT_PROMPT_COMMAND = ^starship module character
        $env.TRANSIENT_PROMPT_INDICATOR = ""
        $env.TRANSIENT_PROMPT_INDICATOR_VI_INSERT = ""
        $env.TRANSIENT_PROMPT_INDICATOR_VI_NORMAL = ""
        $env.TRANSIENT_PROMPT_MULTILINE_INDICATOR = ""
        $env.TRANSIENT_PROMPT_COMMAND_RIGHT = ^starship module time
      '';

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
            rev = "b442c96ec2c51d7b8e14387ef94f354cc48f2a2b";
            hash = "sha256-X1GJ7vLUMv87J+HeU2w8oydRdN2bth40xGeY1jWv3ww=";
          };
          completionTypes = [
            "bat"
            "curl"
            "gh"
            "git"
            "man"
            "nix"
            "ssh"
            "vscode"
          ];
          sourceCommands = map (
            t: "source ${customCompletions}/custom-completions/${t}/${t}-completions.nu"
          ) completionTypes;
        in
        builtins.concatStringsSep "\n" sourceCommands;
    };
  };
}
