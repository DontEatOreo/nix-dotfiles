{pkgs, ...}: pkgs.writeShellScript "yt-dlp-script" (builtins.readFile ./yt-dlp-script.sh)
