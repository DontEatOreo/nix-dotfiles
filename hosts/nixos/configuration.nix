{
  lib,
  inputs,
  system,
  pkgs,
  config,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./hardware.nix
    ./home.nix
    ./networking.nix
    ./packages.nix
    ./programs.nix
    ./services.nix
    ./sound.nix
    ./systemd.nix
    ./users.nix

    ../../shared/cli.nix
    ../../shared/dev.nix
    ../../shared/gnuimp.nix
    ../../shared/programs.nix
    ../../shared/tui.nix
  ];

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

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  time.timeZone = "Europe/Sofia";

  fonts = {
    fontconfig = {
      defaultFonts = {
        monospace = [ "SFMono Nerd Font" ];
        sansSerif = [ "SFProText Nerd Font" ];
        serif = [ "SFProDisplay Nerd Font" ];
        emoji = [ "Twitter Color Emoji" ];
      };
    };
    packages = builtins.attrValues {
      inherit (pkgs)
        fira-code
        fira-code-symbols
        monaspace
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-emoji
        twemoji-color-font
        ;
      inherit (inputs.apple-fonts.packages.${system})
        sf-compact-nerd
        sf-mono-nerd
        sf-pro-nerd
        ;

      nerfonts = pkgs.nerdfonts.override {
        fonts = [
          "DroidSansMono"
          "FiraCode"
          "Monaspace"
          "Noto"
        ];
      };
    };
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "24.11";
}
