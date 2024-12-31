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
        "$os"
        "$directory"
        "$git_branch"
        "$git_state"
        "$git_status"
        "$cmd_duration"
        "$status"
        "$time"
        "$battery"
        "$line_break"
        "$character"
        "$command_timeout"
        "$git_commit"
        "$package"
        "$sudo"
      ];

      os = {
        disabled = false;
        symbols.Macos = " ";
        symbols.NixOS = " ";
      };

      directory = {
        truncate_to_repo = false;
        fish_style_pwd_dir_length = 1;
        truncation_length = 17;
        truncation_symbol = "../";
        read_only = "";
      };

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
        format = "at [$time]($style)";
        style = "bold blue";
      };

      battery = {
        full_symbol = " ";
        charging_symbol = "󰂄 ";
        empty_symbol = " ";
      };
    };
  };
}
