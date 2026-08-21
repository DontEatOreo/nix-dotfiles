{ inputs }:
let
  lib = inputs.nixpkgs.lib;

  dependencies =
    _: prev:
    let
      unstable = import inputs.nixpkgs-unstable {
        localSystem = prev.stdenvNoCC.hostPlatform;
        inherit (prev) config;
      };
      eupkgsScope =
        unstable
        // eupkgsOverlay
        // {
          callPackage = unstable.lib.callPackageWith eupkgsScope;
        };
      eupkgsOverlay = inputs.eupkgs.overlays.default eupkgsScope unstable;
      eupkgs = removeAttrs eupkgsOverlay [ "_internalCallByNamePackageFile" ];
    in
    {
      inherit eupkgs unstable;
    };

  packageDefinitions =
    final: prev:
    let
      dotfilesSourcePins = (import ../npins) { };
    in
    {
      inherit dotfilesSourcePins;
      bluebuild-v2 = final.callPackage ../packages/bluebuild-v2/package.nix { };
      bun2nix = inputs.bun2nix.packages.${final.stdenv.hostPlatform.system}.default;
      gh = final.unstable.gh;
      lldb-mcp-launcher = final.eupkgs.lldb-mcp-launcher;
      ghidra-mcp-headless = final.eupkgs.ghidra-mcp-headless;
      ghidra-mcp = final.callPackage ../packages/ghidra-mcp/package.nix {
        inherit (final) ghidra-mcp-headless;
      };
      # Keep the flake formatter and dev shell at the Justfile's version floor
      # while both pinned nixpkgs package sets still provide 1.57.0.
      just =
        let
          source = dotfilesSourcePins.just;
          inherit (source) version;
          src = source.outPath;
        in
        prev.just.overrideAttrs (previousAttrs: {
          inherit src version;
          cargoDeps = final.rustPlatform.fetchCargoVendor {
            inherit src;
            hash = "sha256-zpP5XLmgQFH4+B97zMhh+iE6kS+PHTh9heH89rXCQo0=";
          };
          doCheck = false;
          doInstallCheck = false;
          meta = previousAttrs.meta // {
            changelog = "https://github.com/casey/just/blob/${version}/CHANGELOG.md";
          };
        });
      ghostty-patched = final.callPackage ../packages/ghostty-patched/package.nix {
        ghostty = final.unstable.ghostty.override {
          zig_0_15 = final.unstable.zig;
        };
      };
      kanata-with-cmd = final.callPackage ../packages/kanata-with-cmd/package.nix { };
      kmscon = prev.kmscon.overrideAttrs (
        _: previousAttrs: {
          # The pin follows upstream main rather than a release tag.
          version = "10.0.1-unstable-2026-07-31";
          src = dotfilesSourcePins.kmscon.outPath;
          buildInputs = previousAttrs.buildInputs ++ [ final.dbus ];
          mesonFlags = (previousAttrs.mesonFlags or [ ]) ++ [ "-Dtests=false" ];
          doCheck = false;
          doInstallCheck = false;
          # The pinned source installs kmscon itself as an ELF binary; only
          # the launcher script contains a command path that needs rewriting.
          postFixup = ''
            substituteInPlace $out/bin/kmscon-launch-gui \
              --replace-fail "inotifywait" "${final.lib.getExe' final.inotify-tools "inotifywait"}"
          '';
        }
      );
      hyper-window-tiling = final.callPackage ../packages/hyper-window-tiling/package.nix { };
      hyper-window-tiling-gnome = final.hyper-window-tiling.gnome;
      hyper-window-tiling-kde = final.hyper-window-tiling.kde;
      dotfiles-python = final.callPackage ../packages/dotfiles-python/package.nix {
        inherit (final.unstable) python314Packages;
      };
      fido-phone = final.callPackage ../packages/fido-phone/package.nix { };
      uresourced = final.callPackage ../packages/uresourced/package.nix { };
      terminal-theme-tools = final.callPackage ../packages/terminal-theme-tools/package.nix { };
      toshy-runtime = final.callPackage ../packages/toshy-runtime/package.nix { };
    };

  packages = lib.composeManyExtensions [
    dependencies
    packageDefinitions
  ];
in
{
  inherit dependencies packages;
  default = packages;
}
