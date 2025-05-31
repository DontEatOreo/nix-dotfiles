{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit ((pkgs.callPackage ../../shared/aliases.nix { osConfig = config; }).programs.zsh)
    shellAliases
    ;
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
  launchd.user.agents."symlink-zsh-config" = {
    script = ''
      ln -sfn "/etc/zprofile" "/Users/${config.system.primaryUser}/.zprofile"
      ln -sfn "/etc/zshenv" "/Users/${config.system.primaryUser}/.zshenv"
      ln -sfn "/etc/zshrc" "/Users/${config.system.primaryUser}/.zshrc"
    '';
    serviceConfig.RunAtLoad = true;
    serviceConfig.StartInterval = 0;
  };

  programs.zsh = {
    enableSyntaxHighlighting = true;
    promptInit = ''
      eval "$(starship init zsh)"
    '';
    interactiveShellInit = ''
      source ${pkgs.oh-my-zsh}/share/oh-my-zsh/oh-my-zsh.sh
      source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh

      eval "$(zoxide init zsh)"
      eval "$(github-copilot-cli alias -- "$0")"

      # Aliases
      ${aliasesToString shellAliases}

      # macOS Specific Aliases
      alias "micfix"="sudo killall coreaudiod"
    '';
  };
}
