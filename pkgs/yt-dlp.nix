{ pkgs, lib }:
let
  optional-dependencies = {
    default = builtins.attrValues {
      inherit (pkgs.python3Packages)
        brotli
        certifi
        mutagen
        pycryptodomex
        requests
        urllib3
        websockets
        ;
    };
    curl-cffi = builtins.attrValues { inherit (pkgs.python3Packages) curl-cffi; };
    secretstorage = builtins.attrValues {
      inherit (pkgs.python3Packages) cffi secretstorage;
    };
  };
in
pkgs.python3Packages.buildPythonApplication {
  pname = "yt-dlp";
  # The websites yt-dlp deals with are a very moving target. That means that
  # downloads break constantly. Because of that, updates should always be backported
  # to the latest stable release.
  version = "2025.06.30-unstable-2025-06-30";
  pyproject = true;

  src = pkgs.fetchFromGitHub {
    owner = "yt-dlp";
    repo = "yt-dlp";
    rev = "30fa54280b363265d0235b0aab3b1725eb0f61b8";
    hash = "sha256-dwBe6oXh7G67kfiI6BqiC0ZHzleR7QlfMiTVXWYW85I=";
  };

  build-system = builtins.attrValues { inherit (pkgs.pkgs.python3Packages) hatchling; };

  # expose optional-dependencies, but provide all features
  dependencies = lib.flatten (lib.attrValues optional-dependencies);

  pythonRelaxDeps = [ "websockets" ];

  # Ensure these utilities are available in $PATH:
  # - ffmpeg: post-processing & transcoding support
  # - rtmpdump: download files over RTMP
  # - atomicparsley: embedding thumbnails
  makeWrapperArgs =
    let
      packagesToBinPath = builtins.attrValues {
        inherit (pkgs)
          atomicparsley
          ffmpeg-headless
          rtmpdump
          ;
      };
    in
    lib.optionals (packagesToBinPath != [ ]) [
      ''--prefix PATH : "${lib.makeBinPath packagesToBinPath}"''
    ];

  setupPyBuildFlags = [ "build_lazy_extractors" ];

  # Requires network
  doCheck = false;

  postInstall = ''
    ln -s "$out/bin/yt-dlp" "$out/bin/youtube-dl"
  '';

  meta = with lib; {
    changelog = "https://github.com/yt-dlp/yt-dlp/blob/HEAD/Changelog.md";
    description = "Command-line tool to download videos from YouTube.com and other sites (youtube-dl fork)";
    homepage = "https://github.com/yt-dlp/yt-dlp/";
    license = licenses.unlicense;
    longDescription = ''
      yt-dlp is a youtube-dl fork based on the now inactive youtube-dlc.

      youtube-dl is a small, Python-based command-line program
      to download videos from YouTube.com and a few more sites.
      youtube-dl is released to the public domain, which means
      you can modify it, redistribute it or use it however you like.
    '';
    mainProgram = "yt-dlp";
    maintainers = with maintainers; [
      SuperSandro2000
      donteatoreo
    ];
  };
}
