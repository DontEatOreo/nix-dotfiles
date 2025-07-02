{
  lib,
  python3Packages,
  fetchFromGitHub,
  ffmpeg-headless,
  rtmpdump,
  atomicparsley,
  pandoc,
  atomicparsleySupport ? true,
  ffmpegSupport ? true,
  rtmpSupport ? true,
  withAlias ? false, # Provides bin/youtube-dl for backcompat
  nix-update-script,
}:

python3Packages.buildPythonApplication rec {
  pname = "yt-dlp";
  # The websites yt-dlp deals with are a very moving target. That means that
  # downloads break constantly. Because of that, updates should always be backported
  # to the latest stable release.
  version = "2025.06.25";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "yt-dlp";
    repo = "yt-dlp";
    tag = version;
    hash = "sha256-ZEhruWP4RBeyw2vCF0CG7xvMur8RzVmTgi5Kz4nkNII=";
  };

  build-system = with python3Packages; [ hatchling ];

  nativeBuildInputs = [ pandoc ];

  # expose optional-dependencies, but provide all features
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
    rm -f yt-dlp.1.temp.md

    mkdir -p completions/bash completions/zsh completions/fish
    python devscripts/bash-completion.py
    python devscripts/zsh-completion.py completions/zsh/_yt-dlp  
    python devscripts/fish-completion.py completions/fish/yt-dlp.fish

    cp README.md README.txt
  '';

  # Ensure these utilities are available in $PATH:
  # - ffmpeg: post-processing & transcoding support
  # - rtmpdump: download files over RTMP
  # - atomicparsley: embedding thumbnails
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
    install -Dm644 yt-dlp.1 $out/share/man/man1/yt-dlp.1

    install -Dm644 completions/bash/yt-dlp $out/share/bash-completion/completions/yt-dlp
    install -Dm644 completions/zsh/_yt-dlp $out/share/zsh/site-functions/_yt-dlp  
    install -Dm644 completions/fish/yt-dlp.fish $out/share/fish/vendor_completions.d/yt-dlp.fish

    install -Dm644 README.txt $out/share/doc/yt-dlp/README.txt
    install -Dm644 Changelog.md $out/share/doc/yt-dlp/Changelog.md

    ${lib.optionalString withAlias ''
      ln -s "$out/bin/yt-dlp" "$out/bin/youtube-dl"
    ''}
  '';

  passthru.updateScript = nix-update-script { };

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
