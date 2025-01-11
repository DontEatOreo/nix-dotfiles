{ lib, config, ... }:
{
  options.hm.starship.enable = lib.mkEnableOption "Starship";

  config = lib.mkIf config.hm.starship.enable {
    programs.starship.enable = true;
    programs.starship.settings = {
      add_newline = true;
      command_timeout =
        let
          secToMin = s: s * 1000;
        in
        secToMin 10;

      format = lib.concatStrings [
        "$shell"
        "$os"
        "$directory"
        "$git_branch"
        "$git_state"
        "$git_status"
        "$cmd_duration"
        "$status"
        "$time"
        "$nix_shell"
        "$battery"
        "$line_break"
        "$sudo"
        "\${custom.yazi}"
        "$character"
        "$command_timeout"
        "$git_commit"
      ];

      shell = {
        disabled = false;
        style = "cyan bold";
        fish_indicator = "λ";
        powershell_indicator = ">_";
        bash_indicator = "\\$";
        zsh_indicator = "%";
        format = "\\[[$indicator]($style)\\] ";
      };

      os = {
        disabled = false;
        style = "bold blue";
        symbols.Macos = "󰀵 ";
        symbols.NixOS = " ";
        symbols.Linux = " ";
      };

      directory = {
        truncate_to_repo = false;
        fish_style_pwd_dir_length = 1;
        truncation_symbol = "../";
        read_only = "";
        format = "in [$path]($style)[$read_only]($read_only_style) ";
      };

      git_branch.symbol = "󰊢 ";

      git_status = {
        ahead = " \${count} ";
        diverged = " \${ahead_count}\${behind_count} ";
        behind = " \${count} ";
        stashed = " \${count} ";
        untracked = " \${count} ";
        modified = " \${count} ";
        staged = "󰸞 \${count} ";
        conflicted = "󰞇 \${count} ";
      };

      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[✗](bold red)";
        vimcmd_symbol = "[V](bold red)";
      };

      sudo = {
        style = "bold red";
        symbol = " ";
        disabled = false;
      };

      time = {
        disabled = false;
        time_format = "%X";
        format = "at [$time]($style) ";
        style = "bold blue";
      };

      battery = {
        full_symbol = " ";
        charging_symbol = "󰂄 ";
        empty_symbol = " ";
      };

      nix_shell = {
        disabled = false;
        impure_msg = "[impure shell](bold red)";
        pure_msg = "[pure shell](bold green)";
        unknown_msg = "[unknown shell](bold yellow)";
        style = "bold blue";
        format = "inside ( $state) ";
      };

      custom.yazi = {
        when = ''test -n "$YAZI_LEVEL"'';
        description = "Indicate when the shell was launched by `yazi`";
        symbol = "󰇥 Yazi";
        style = "bold yellow";
        format = "in [$symbol]($style) ";
      };
    };
  };
}
