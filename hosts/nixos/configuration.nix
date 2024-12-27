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
        monospace = [ "Monaspice Kr Nerd Font" ];
        sansSerif = [ "Noto Nerd Font" ];
        serif = [ "Noto Nerd Font" ];
        emoji = [ "Twitter Color Emoji" ];
      };
    };
    packages = builtins.attrValues {
      Ubuntu = pkgs.nerd-fonts.ubuntu;
      UbuntuMono = pkgs.nerd-fonts.ubuntu-mono;
      UbuntuSans = pkgs.nerd-fonts.ubuntu-sans;
      FiraCode = pkgs.nerd-fonts.fira-code;
      Monaspace = pkgs.nerd-fonts.monaspace;
      Noto = pkgs.nerd-fonts.noto;

      inherit (pkgs)
        noto-fonts-cjk-sans
        noto-fonts-emoji
        twemoji-color-font
        ;
      inherit (inputs.apple-fonts.packages.${system})
        sf-compact-nerd
        sf-mono-nerd
        sf-pro-nerd
        ;
    };
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "24.11";
}
