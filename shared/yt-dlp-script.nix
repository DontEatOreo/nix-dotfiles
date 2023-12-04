{pkgs, ...}:
pkgs.writeShellScript "yt-dlp-script" ''
  commonArgs=(--progress --console-title --embed-thumbnail --embed-metadata)
  audioArgs=(--extract-audio --audio-quality 0)
  videoArgs=(-S vcodec:h264,ext:mp4:m4a)
  outputArgs=(-o "%(display_id)s.%(ext)s")
  finalArgs=(--ignore-config)

  url=""
  timeRange=""
  cutOption=false
  format=""

  for arg in "$@"
  do
      if [[ $arg =~ ^http ]]; then
          url=$arg
      elif [[ $arg =~ ^[0-9]+-[0-9]+$ ]]; then
          timeRange=$arg
      elif [[ $arg == *"-cut"* ]]; then
          cutOption=true
          format=$arg
      elif [[ $arg == "mp4" || $arg == "mp3" || $arg == "m4a" ]]; then
          format=$arg
      fi
  done

  if [[ -z $url ]]; then
      echo "Error: Missing URL"
      exit 1
  fi

  if [[ $cutOption == true && -z $timeRange ]]; then
      echo "Error: Missing time range for -cut option"
      exit 1
  fi

  cutArgs=(--download-sections "*''${timeRange}" --force-keyframes-at-cuts)

  case $format in
    m4a)
      yt-dlp "''${url}" "''${audioArgs[@]}" --audio-format m4a "''${commonArgs[@]}" "''${outputArgs[@]}"
      ;;
    m4a-cut)
      yt-dlp "''${url}" "''${audioArgs[@]}" --audio-format m4a "''${cutArgs[@]}" "''${commonArgs[@]}" "''${outputArgs[@]}" "''${finalArgs[@]}"
      ;;
    mp3)
      yt-dlp "''${url}" "''${audioArgs[@]}" --audio-format mp3 "''${commonArgs[@]}" "''${outputArgs[@]}" "''${finalArgs[@]}"
      ;;
    mp3-cut)
      yt-dlp "''${url}" "''${audioArgs[@]}" --audio-format mp3 "''${cutArgs[@]}" "''${commonArgs[@]}" "''${outputArgs[@]}" "''${finalArgs[@]}"
      ;;
    mp4)
      yt-dlp "''${url}" "''${videoArgs[@]}" "''${commonArgs[@]}" "''${outputArgs[@]}" "''${finalArgs[@]}"
      ;;
    mp4-cut)
      yt-dlp "''${url}" "''${videoArgs[@]}" "''${cutArgs[@]}" "''${commonArgs[@]}" "''${outputArgs[@]}" "''${finalArgs[@]}"
      ;;
    *)
      echo "Invalid format"
      ;;
  esac
''
