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
  toshySource = (import ../npins { }).toshy.outPath;

  equicordParseRules = builtins.fromJSON (
    builtins.readFile "${inputs.nixcord}/modules/plugins/parse-rules.json"
  );
  blackRoseDollPalette = builtins.fromJSON (
    builtins.readFile ../dotfiles/.chezmoitemplates/black_rose_doll_palette.json
  );
  equicordExceptionsCss = builtins.readFile ../packages/equicord-settings/quick-css.css;
  equicordQuickCss = import ../packages/equicord-settings/theme.nix {
    inherit lib;
    palette = blackRoseDollPalette;
    exceptions = equicordExceptionsCss;
  };
  equicordSettings =
    (import ../packages/equicord-settings/settings.nix {
      inherit lib;
      parseRules = equicordParseRules;
    })
    // {
      quickCss = equicordQuickCss;
    };

  mkPackages =
    pkgs:
    let
      ghidraMcp = pkgs.ghidra-mcp;
      ghidraMcpHeadless = pkgs.ghidra-mcp-headless;
    in
    {
      inherit (pkgs) bun2nix;
      default = ghidraMcp;
      dotfiles-nix-tools = pkgs.buildEnv {
        name = "dotfiles-nix-tools";
        paths = with pkgs; [
          deadnix
          nh
          nil
          nix-output-monitor
          nix-tree
          nixd
          nixfmt
          statix
        ];
      };
      inherit (pkgs) dotfiles-python;
      equicord-settings = pkgs.callPackage ../packages/equicord-settings/package.nix {
        quickCss = equicordQuickCss;
        settings = equicordSettings.jsonConfig;
      };
      ghidra-mcp = ghidraMcp;
      ghidra-mcp-bridge = ghidraMcpHeadless.bridge;
      ghidra-mcp-headless = ghidraMcpHeadless;
      ghidra-mcp-httpd = ghidraMcpHeadless.httpd;
      ghidra-mcp-launcher = ghidraMcpHeadless.launcher;
      inherit (ghidraMcpHeadless) ghidra;
      inherit (pkgs) kanata-with-cmd terminal-theme-tools;
    }
    // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
      inherit (pkgs)
        bluebuild-v2
        check-jsonschema
        ghostty-patched
        hyper-window-tiling-gnome
        hyper-window-tiling-kde
        kmscon
        toshy-runtime
        uresourced
        ;
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
      ghidra-mcp = appFor (lib.getExe packages.ghidra-mcp) "Run the Ghidra MCP service";
      ghidra-mcp-headless = appFor (lib.getExe' packages.ghidra-mcp-launcher "ghidra-mcp-headless") "Run the headless Ghidra MCP backend";
      ghidra-mcp-httpd = appFor (lib.getExe' packages.ghidra-mcp-httpd "ghidra-mcp-httpd") "Run the Ghidra MCP HTTP server";
      ghidra-mcp-bridge = appFor (lib.getExe' packages.ghidra-mcp-bridge "ghidra-mcp-bridge") "Run the Ghidra MCP bridge";
      default = appFor (lib.getExe packages.ghidra-mcp) "Run the Ghidra MCP service";
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
              "${toshySource}/nix/nixos-module.nix"
              inputs.browser.nixosModules.default
              inputs.determinate.nixosModules.default
              inputs.nixcord.nixosModules.nixcord
              inputs.vicinae.nixosModules.default
            ];

            # Keep every locally packaged program used by NixOS identical to
            # the corresponding packages.<system> flake output. Consumers of
            # this module do not have to recreate our overlay or package
            # selection.
            _module.args = {
              inherit inputs;
              dotfilesPackages = config.packages;
              dotfilesEquicordSettings = equicordSettings;
            };
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
        };
        overlays = [ overlays.default ];
      };

      packages = mkPackages pkgs;
      apps = mkApps config.packages;
    };
}
