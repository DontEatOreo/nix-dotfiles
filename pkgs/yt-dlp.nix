{
  lib,
  python3Packages,
  fetchFromGitHub,
  ffmpeg-headless,
  rtmpdump,
  atomicparsley,
  pandoc,
  installShellFiles,
  atomicparsleySupport ? true,
  ffmpegSupport ? true,
  rtmpSupport ? true,
}:

python3Packages.buildPythonApplication rec {
  pname = "yt-dlp";
  version = "2025.07.21-unstable-2025-07-25";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "yt-dlp";
    repo = "yt-dlp";
    rev = "61d4cd0bc01be6ebe11fd53c2d3805d1a2058990";
    hash = "sha256-VNUkCdrzbOwD+iD9BZUQFJlWXRc0tWJAvLnVKNZNPhQ=";
  };

  build-system = with python3Packages; [ hatchling ];

  nativeBuildInputs = [
    installShellFiles
    pandoc
  ];

  dependencies = lib.flatten (lib.attrValues optional-dependencies);

  optional-dependencies = {
    default = with python3Packages; [
      brotli
      certifi
      mutagen
      pycryptodomex
      requests
      urllib3
      websockets
    ];
    curl-cffi = [ python3Packages.curl-cffi ];
    secretstorage = with python3Packages; [
      cffi
      secretstorage
    ];
  };

  pythonRelaxDeps = [ "websockets" ];

  preBuild = ''
    python devscripts/make_lazy_extractors.py
  '';

  postBuild = ''
    python devscripts/prepare_manpage.py yt-dlp.1.temp.md
    pandoc -s -f markdown-smart -t man yt-dlp.1.temp.md -o yt-dlp.1
    rm yt-dlp.1.temp.md

    mkdir -p completions/{bash,fish,zsh}
    python devscripts/bash-completion.py completions/bash/yt-dlp
    python devscripts/zsh-completion.py completions/zsh/_yt-dlp
    python devscripts/fish-completion.py completions/fish/yt-dlp.fish
  '';

  makeWrapperArgs =
    let
      packagesToBinPath =
        [ ]
        ++ lib.optional atomicparsleySupport atomicparsley
        ++ lib.optional ffmpegSupport ffmpeg-headless
        ++ lib.optional rtmpSupport rtmpdump;
    in
    lib.optionals (packagesToBinPath != [ ]) [
      ''--prefix PATH : "${lib.makeBinPath packagesToBinPath}"''
    ];

  # Requires network
  doCheck = false;

  postInstall = ''
    installManPage yt-dlp.1

    installShellCompletion \
      --bash completions/bash/yt-dlp \
      --fish completions/fish/yt-dlp.fish \
      --zsh completions/zsh/_yt-dlp

    ln -s "$out/bin/yt-dlp" "$out/bin/youtube-dl"

    install -Dm644 Changelog.md README.md -t "$out/share/doc/yt_dlp"
  '';
}
