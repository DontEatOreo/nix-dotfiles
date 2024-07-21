{ pkgs, ... }:
let
  dropNLines =
    path: n:
    let
      rawContent = builtins.readFile path;
      lines = builtins.split "\n" rawContent;
      droppedFirstNLines = pkgs.lib.drop n lines;
      removedEmptyLines = pkgs.lib.lists.remove "" droppedFirstNLines;
      finalLines = pkgs.lib.lists.remove [ ] removedEmptyLines;
    in
    builtins.concatStringsSep "\n" finalLines;
in
pkgs.lib.getExe (
  pkgs.writeShellApplication {
    name = "yt-dlp-script";
    text = dropNLines ./yt-dlp-script.sh 1;
    runtimeInputs = builtins.attrValues {
      inherit (pkgs)
        ffmpeg-full
        yt-dlp
        jq
        bc
        ;
    };
  }
)
