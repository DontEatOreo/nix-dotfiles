{
  lib,
  pkgs,
  config,
  ...
}:
{
  imports = [
    ./hardware.nix
    ./packages.nix
    ./programs.nix
    ./services.nix
    ./systemd.nix
    ./users.nix
    ./hardware-configuration.nix

    ../../shared/cli.nix
    ../../shared/dev.nix
    ../../shared/gnuimp.nix
    #../../shared/latex.nix # Disabled by default due to file size
    ../../shared/tui.nix
    ../../shared/programs.nix
  ];

  nixOS = {
    gnome.enable = true;
  };

  shared = {
    nix.enable = true;
    nixpkgs.enable = true;
  };

  environment = {
    sessionVariables = {
      NIXOS_OZONE_WL = "1";
    };

    # Add inputs to legacy (nix2) channels, making legacy nix commands consistent
    etc = lib.mapAttrs' (name: value: {
      name = "nix/path/${name}";
      value.source = value.flake;
    }) config.nix.registry;
  };

  networking = {
    hostName = "nyx";
    networkmanager.enable = true;
  };

  # Keyboard layout
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };
  };

  security.rtkit.enable = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  time.timeZone = "Europe/Sofia";

  fonts = {
    fontconfig = {
      enable = true;
      defaultFonts = {
        monospace = [ "Liga SFMono Nerd Font" ];
        sansSerif = [ "SF Pro Text" ];
        serif = [ "New York Medium" ];
        emoji = [ "Twitter Color Emoji" ];
      };
    };
    packages = builtins.attrValues {
      mplus-outline-fonts = pkgs.mplus-outline-fonts.githubRelease;
      inherit (pkgs)
        noto-fonts
        noto-fonts-cjk
        noto-fonts-emoji
        liberation_ttf
        fira-code
        fira-code-symbols
        dina-font
        proggyfonts
        meslo-lgs-nf
        victor-mono
        monaspace
        twemoji-color-font
        sarasa-gothic
        ;

      nerfonts = pkgs.nerdfonts.override {
        fonts = [
          "FiraCode"
          "DroidSansMono"
        ];
      };
    };
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "24.05";
}
