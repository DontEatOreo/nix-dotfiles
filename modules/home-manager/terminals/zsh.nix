{
  pkgs,
  lib,
  config,
  system,
  ...
}:
let
  isLinux = builtins.match ".*linux.*" system != null;
  nixConfigPath = "/etc/nixos/";
in
{
  options.hm.zsh.enable = lib.mkEnableOption "Declerative Zsh";

  config = lib.mkIf config.hm.zsh.enable {
    assertions = [
      {
        assertion = isLinux;
        message = "Declerative Zsh is only available on Linux";
      }
    ];
    programs.zsh = {
      enable = true;
      autosuggestion.enable = true;
      syntaxHighlighting = {
        enable = true;
        highlighters = [ "brackets" ];
      };
      enableVteIntegration = true;
      autocd = true;
      initExtraFirst = ''
        eval "$(github-copilot-cli alias -- "$0")"
      '';
      historySubstringSearch.enable = true;
      plugins = [
        {
          name = "fast-syntax-highlighting";
          src = pkgs.zsh-fast-syntax-highlighting;
        }
        {
          name = "powerlevel10k";
          src = pkgs.zsh-powerlevel10k;
          file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
        }
        {
          name = "powerlevel10k-config";
          src = ../config;
          file = "p10k.zsh";
        }
        {
          name = "fzf-tab";
          src = pkgs.zsh-fzf-tab;
        }
        {
          name = "nix-shell";
          src = pkgs.zsh-nix-shell;
        }
      ];
      oh-my-zsh = {
        enable = true;
        plugins = [
          "colorize"
          "direnv"
          "docker"
          "dotnet"
          "fzf"
          "gitfast"
          "podman"
          "ssh"
          "vscode"
        ];
      };
      shellAliases = import ../../../shared/aliases.nix {
        inherit (pkgs) writeScriptBin;
        inherit (lib) getExe;
        inherit system nixConfigPath;
      };
    };
  };
}
