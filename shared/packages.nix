{
  pkgs,
  inputs,
  lib,
  config,
  ...
}:
let
  pkgsMaster = inputs.nixpkgs-master.legacyPackages.${config.nixpkgs.hostPlatform.system};
in
{
  environment.systemPackages =
    builtins.attrValues {
      # Nix Related
      inherit (pkgsMaster) nil;
      inherit (pkgs) nixfmt-rfc-style;

      # Rust re-implementations of coreutils
      inherit (pkgsMaster)
        uutils-coreutils-noprefix
        uutils-diffutils
        uutils-findutils
        ;

      # Rust
      inherit (inputs.rust-overlay.packages.${config.nixpkgs.hostPlatform.system}) default;

      # Modern Rust Alternatives
      inherit (pkgs)
        bat # cat
        bottom # htop & btop
        broot # tree
        delta # difff
        duf # df
        dust # du
        eza # ls
        fd # find
        procs # ps
        ripgrep # grep
        sd # sed
        xh # curl
        ;

      # TUI
      inherit (pkgs)
        btop
        ncdu
        nix-tree
        ;

      # Media
      inherit (pkgs)
        ffmpeg-full
        imagemagick
        mediainfo
        yt-dlp
        ;

      # File Management & Archiving
      inherit (pkgs)
        rar
        unrar
        unzip
        zip
        ;
      inherit (pkgs)
        pandoc
        rsync
        tree
        xz
        ;

      # Text Processing & Viewing
      inherit (pkgs)
        hexyl # CLI hex viewer
        jq # CLI JSON processor
        less
        ;

      # Networking
      inherit (pkgs)
        curl
        dnsutils # `dig`, `nslookup`, etc.
        netcat-gnu # GNU netcat
        nmap
        openssh_hpn # SSH client/server (High Performance Networking patches)
        wget
        ;

      # System Information & Monitoring
      inherit (pkgs)
        file
        lsof # List open files
        pciutils # lspci
        smartmontools # S.M.A.R.T. disk health monitoring tools
        ;

      # Misc
      inherit (pkgs)
        hyperfine
        tokei
        patch
        github-copilot-cli
        shellcheck
        tldr
        which
        ;
    }
    ++ lib.optionals config.nixpkgs.hostPlatform.isLinux (
      builtins.attrValues {
        inherit (pkgs)
          networkmanagerapplet
          pavucontrol # PulseAudio Volume Control GUI
          playerctl # Control media players via MPRIS (CLI)
          ;

        inherit (pkgs.kdePackages) ffmpegthumbs;
        inherit (pkgs) nufraw-thumbnailer;

        inherit (pkgs.kdePackages) breeze breeze-gtk breeze-icons;
      }
    );
}
