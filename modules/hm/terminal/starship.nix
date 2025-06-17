{ lib, config, ... }:
{
  options.hm.starship.enable = lib.mkEnableOption "Starship";

  config = lib.mkIf config.hm.starship.enable {
    programs.nushell.envFile.text = ''
      $env.TRANSIENT_PROMPT_COMMAND = ^starship module character
      $env.TRANSIENT_PROMPT_INDICATOR = ""
      $env.TRANSIENT_PROMPT_INDICATOR_VI_INSERT = ""
      $env.TRANSIENT_PROMPT_INDICATOR_VI_NORMAL = ""
      $env.TRANSIENT_PROMPT_MULTILINE_INDICATOR = ""
      $env.TRANSIENT_PROMPT_COMMAND_RIGHT = ^starship module time
    '';
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
        "\${custom.jj_icon}"
        "\${custom.jj_info}"
        "$nix_shell"
        "$line_break"
        "$sudo"
        "$character"
        "$command_timeout"
      ];

      right_format = lib.concatStrings [
        "$cmd_duration"
        "$time"
      ];

      shell = {
        disabled = false;
        style = "cyan bold";
        fish_indicator = "λ";
        powershell_indicator = ">_";
        bash_indicator = "\\$";
        zsh_indicator = "%";
        nu_indicator = ">";
        format = "\\[[$indicator]($style)\\] ";
      };

      os = {
        disabled = false;
        style = "bold blue";
        symbols.Macos = "󰀵 ";
        symbols.NixOS = "󱄅 ";
        symbols.Linux = " ";
      };

      directory = {
        truncate_to_repo = false;
        fish_style_pwd_dir_length = 1;
        truncation_symbol = "../";
        format = "in [$path]($style) ";
      };

      custom.jj_icon = {
        detect_folders = [ ".jj" ];
        format = "on [$symbol]($style) ";
        style = "bold fg:#F4B8E5";
        symbol = "󰠬";
        when = "jj root --ignore-working-copy";
      };

      custom.jj_info = {
        command = ''
          jj log --color=always --revisions @ --no-graph --ignore-working-copy --limit 1 --template 'change_id.shortest() ++ " " ++ commit_id.shortest() ++ if(bookmarks, " " ++ bookmarks.map(|b| truncate_start(14, b.name(), "..")).join(", "), "") ++ raw_escape_sequence("\x1b[1;32m") ++ " " ++ if(empty, "(empty)", coalesce(truncate_start(24, description.first_line(), ".."), "(no description)")) ++ raw_escape_sequence("\x1b[0m")' | str trim
        '';
        detect_folders = [ ".jj" ];
        format = "\\[$output\\] ";
        shell = [ "nu" ];
        when = "jj root --ignore-working-copy";
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

      nix_shell = {
        disabled = false;
        impure_msg = "[impure shell](bold red)";
        pure_msg = "[pure shell](bold green)";
        unknown_msg = "[unknown shell](bold yellow)";
        style = "bold blue";
        format = "inside \\( $state\\) ";
      };
    };
  };
}
