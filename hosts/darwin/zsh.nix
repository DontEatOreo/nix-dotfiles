{
  pkgs,
  lib,
  config,
  username,
  system,
  ...
}:
let
  nixConfigPath = "${config.users.users.${username}.home}/.nixpkgs";
  shellAliases = import ../../shared/aliases.nix {
    inherit (pkgs) writeScriptBin;
    inherit (lib) getExe;
    inherit system nixConfigPath;
  };
  aliasesToString =
    aliases:
    let
      escapeValue = value: builtins.replaceStrings [ "\n" ] [ "\\n" ] value;
      transformed = lib.mapAttrsToList (name: value: "alias \"${name}\"=\"${escapeValue value}\"") (
        lib.filterAttrs (_: v: v != null && v != "") aliases
      );
    in
    builtins.concatStringsSep "\n" transformed;
in
{
  programs.zsh = {
    enableSyntaxHighlighting = true;
    promptInit = ''
      source ${../../modules/home-manager/config/p10k.zsh}
      source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
    '';
    interactiveShellInit = ''
      source ${pkgs.oh-my-zsh}/share/oh-my-zsh/oh-my-zsh.sh
      source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh

      eval "$(zoxide init zsh)"
      eval "$(github-copilot-cli alias -- "$0")"

      # Aliases
      ${aliasesToString shellAliases}
    '';
    variables = {
      SHELL = lib.getExe pkgs.zsh;
      ZDOTDIR = config.users.users.${username}.home;
      MANPAGER = "nvim +Man!";
    };
  };
}
