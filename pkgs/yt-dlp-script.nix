{
  writeShellApplication,
  bc,
  cacert,
  choose,
  dust,
  fd,
  ffmpeg_7-full,
  gum,
  jq,
  sd,
  yt-dlp,
}:

writeShellApplication {
  name = "yt-dlp-script";
  text = builtins.readFile ../scripts/yt-dlp-script.sh;
  runtimeInputs = [
    bc
    cacert
    choose
    dust
    fd
    ffmpeg_7-full
    gum
    jq
    sd
    yt-dlp
  ];
}
