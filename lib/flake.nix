{
  inputs,
  lib,
  ...
}:
let
  # Keep this list explicit: these are the systems used by this repository's
  # NixOS host and macOS workstation, and for which its custom packages are
  # intentionally supported.
  systems = [
    "aarch64-darwin"
    "x86_64-linux"
  ];

  overlays = import ../overlays { inherit inputs; };

  equicordParseRules = builtins.fromJSON (
    builtins.readFile "${inputs.nixcord}/modules/plugins/parse-rules.json"
  );
  blackRoseDollPalette = builtins.fromJSON (
    builtins.readFile ../dotfiles/.chezmoitemplates/black_rose_doll_palette.json
  );
  equicordExceptionsCss = builtins.readFile ../packages/equicord/quickCss.css;
  equicordQuickCss = import ./equicord-theme.nix {
    inherit lib;
    palette = blackRoseDollPalette;
    exceptions = equicordExceptionsCss;
  };
  equicordSettings =
    (import ../modules/equicord/settings.nix {
      inherit lib;
      parseRules = equicordParseRules;
    })
    // {
      quickCss = equicordQuickCss;
    };

  mkEquicordSettingsPackage =
    pkgs:
    pkgs.runCommand "equicord-settings"
      {
        meta.description = "Equicord settings shared by NixOS and non-NixOS installations";
        nativeBuildInputs = [ pkgs.jq ];
        strictDeps = true;
      }
      ''
        mkdir -p "$out"
        jq . ${pkgs.writeText "equicord-settings.json" (builtins.toJSON equicordSettings.jsonConfig)} > "$out/settings.json"
        cp ${pkgs.writeText "equicord-quick-css" equicordQuickCss} "$out/quickCss.css"
      '';

  mkPackages =
    pkgs:
    let
      ghidraMcp = pkgs.ghidra-mcp;
      ghidraMcpHeadless = pkgs.ghidra-mcp-headless;
    in
    {
      bun2nix = pkgs.bun2nix;
      default = ghidraMcp;
      dotfiles-python = pkgs.dotfiles-python;
      equicord-settings = mkEquicordSettingsPackage pkgs;
      ghidra-mcp = ghidraMcp;
      ghidra-mcp-bridge = ghidraMcpHeadless.bridge;
      ghidra-mcp-headless = ghidraMcpHeadless;
      ghidra-mcp-httpd = ghidraMcpHeadless.httpd;
      ghidra-mcp-launcher = ghidraMcpHeadless.launcher;
      ghidra = ghidraMcpHeadless.ghidra;
      kanata-with-cmd = pkgs.kanata-with-cmd;
    }
    // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
      bluebuild-v2 = pkgs.bluebuild-v2;
      check-jsonschema = pkgs.check-jsonschema;
      ghostty-patched = pkgs.ghostty-patched;
      hyper-window-tiling-gnome = pkgs.hyper-window-tiling-gnome;
      hyper-window-tiling-kde = pkgs.hyper-window-tiling-kde;
      kmscon = pkgs.kmscon;
      terminal-theme-tools = pkgs.terminal-theme-tools;
      uresourced = pkgs.uresourced;
    }
    // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
      fido-phone = pkgs.fido-phone;
    };

  mkApps =
    packages:
    let
      appFor = program: description: {
        type = "app";
        inherit program;
        meta = { inherit description; };
      };
    in
    {
      ghidra-mcp = appFor "${packages.ghidra-mcp}/bin/ghidra-mcp-serve" "Run the Ghidra MCP service";
      ghidra-mcp-headless = appFor "${packages.ghidra-mcp-launcher}/bin/ghidra-mcp-headless" "Run the headless Ghidra MCP backend";
      ghidra-mcp-httpd = appFor "${packages.ghidra-mcp-httpd}/bin/ghidra-mcp-httpd" "Run the Ghidra MCP HTTP server";
      ghidra-mcp-bridge = appFor "${packages.ghidra-mcp-bridge}/bin/ghidra-mcp-bridge" "Run the Ghidra MCP bridge";
      default = appFor "${packages.ghidra-mcp}/bin/ghidra-mcp-serve" "Run the Ghidra MCP service";
    };

in
{
  inherit systems;

  partitionedAttrs = {
    checks = "dev";
    devShells = "dev";
    formatter = "dev";
    nixosConfigurations = "nixos";
    nixosModules = "nixos";
  };

  partitions.dev = {
    extraInputsFlake = ../nix/dev;
    module = ../nix/dev/flake-module.nix;
  };

  partitions.nixos = {
    extraInputsFlake = ../nix/nixos;
    module =
      {
        inputs,
        moduleWithSystem,
        ...
      }:
      let
        nixosModule = moduleWithSystem (
          { config, ... }:
          { ... }:
          {
            imports = [
              ../modules/nixos
              inputs.browser.nixosModules.default
              inputs.determinate.nixosModules.default
              inputs.nixcord.nixosModules.nixcord
            ];

            # Keep every locally packaged program used by NixOS identical to
            # the corresponding packages.<system> flake output. Consumers of
            # this module do not have to recreate our overlay or package
            # selection.
            _module.args.inputs = inputs;
            _module.args.dotfilesPackages = config.packages;
            _module.args.dotfilesEquicordSettings = equicordSettings;
          }
        );
      in
      {
        flake = {
          nixosModules.default = nixosModule;
          nixosConfigurations = import ../hosts/linux {
            inherit inputs;
            inherit nixosModule;
          };
        };
      };
  };

  flake = {
    lib = {
      inherit equicordQuickCss;
      equicordSettingsJson = equicordSettings.jsonConfig;
      supportedSystems = systems;
    };

    inherit overlays;
  };

  perSystem =
    {
      config,
      pkgs,
      system,
      ...
    }:
    {
      _module.args.pkgs = import inputs.nixpkgs {
        localSystem = system;
        config = {
          allowUnfree = true;
          android_sdk.accept_license = true;
        };
        overlays = [ overlays.default ];
      };

      packages = mkPackages pkgs;
      apps = mkApps config.packages;
    };
}
