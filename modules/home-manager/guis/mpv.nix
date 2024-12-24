{ lib, config, ... }:
{
  options.hm.mpv.enable = lib.mkEnableOption "MPV";

  config = lib.mkIf config.hm.mpv.enable {
    programs.mpv = {
      enable = true;
      bindings = {
        # Playback Control
        "SPACE" = "cycle pause";
        "MBTN_LEFT" = "cycle pause";
        "f" = "cycle fullscreen";
        "Z-Q" = "quit";
        "L" = "ab_loop"; # Set A-B loop points
        "o" = "cycle osc; cycle osd-bar"; # Toggle on-screen controller and OSD bar

        # Volume Control
        "UP" = "add volume 2";
        "DOWN" = "add volume -2";
        "m" = "cycle mute";

        # Seeking
        "LEFT" = "seek -5"; # Seek backward 5 seconds
        "RIGHT" = "seek 5"; # Seek forward 5 seconds
        "Shift+LEFT" = "seek -60"; # Seek backward 60 seconds
        "Shift+RIGHT" = "seek +60"; # Seek forward 60 seconds
        "," = "frame-back-step";
        "." = "frame-step";

        # Subtitle Control
        "v" = "cycle sub"; # Toggle subtitles
        "s" = "cycle sub"; # Switch subtitle tracks

        # Audio Control
        "a" = "cycle audio"; # Switch audio tracks

        # Playback Speed Control
        "[" = "add speed -0.1";
        "]" = "add speed 0.1";
        "BS" = "set speed 1";
      };

      config = {
        # Volume Settings
        volume = 50; # Default volume level
        volume-max = 120; # Maximum volume level

        # Screenshot Settings
        screenshot-directory = "~/Pictures/mpv_screenshots";
        screenshot-format = "png";
        screenshot-template = "%F_%p";

        # Cache Settings
        cache-secs = 3 * 100; # Cache duration in seconds
        demuxer-readahead-secs = 20; # Read ahead 20 seconds, so ya don't get no interruptions
        cache-pause = "yes"; # Pause and buffer when ya hit pause, keep it smooth

        # YouTube Download Settings
        ytdl-format = "bestvideo[height<=?1080]+bestaudio/best";
        ytdl = "yes";

        # Subtitle Settings
        sub-font-size = 36;
        sub-color = "#FFFFFF";

        # Video Settings
        interpolation = "no"; # No fancy frame interpolation, keep it real
        deinterlace = "no"; # No deinterlacin', keep them lines if they got 'em
        hwdec = "no"; # No hardware decodin', let the CPU handle it for accuracy
        loop-file = "inf";
        loop-playlist = "inf";

        # Audio Settings
        audio-pitch-correction = "no";
        audio-delay = 0;

        # General Settings
        keep-open = "yes"; # Don't close video when it finishes
      };
    };
  };
}
