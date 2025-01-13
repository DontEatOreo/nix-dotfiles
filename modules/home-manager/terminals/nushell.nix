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
    programs.nushell = {
      enable = true;
      shellAliases = {
        # Directories
        cd = "z";
        dc = "zi";

        # Editors
        v = "nvim";
        vi = "nvim";
        vim = "nvim";

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
      };

      plugins = builtins.attrValues {
        inherit (pkgs.nushellPlugins)
          formats
          highlight
          query
          units
          ;
      };

      configFile.text = ''
        # Generic
        $env.EDITOR = "nvim";
        $env.VISUAL = "nvim";
        $env.config.show_banner = false;
        $env.config.buffer_editor = "nvim";

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
            rev = "a9b829115ff3c77981616ae777379fc0bd4dc998";
            hash = "sha256-fIayTOyJCqOkFUkmghBQJfCp8s8oNrdUi+/BuOjcbTU=";
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
