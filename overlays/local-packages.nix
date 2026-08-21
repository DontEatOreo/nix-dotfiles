{ inputs, lib }:
final: _prev:
let
  packageFiles = {
    bluebuild-v2 = ../packages/bluebuild-v2/package.nix;
    dotfiles-python = ../packages/dotfiles-python/package.nix;
    ghidra-mcp = ../packages/ghidra-mcp/package.nix;
    ghostty-patched = ../packages/ghostty-patched/package.nix;
    hyper-window-tiling = ../packages/hyper-window-tiling/package.nix;
    kanata-with-cmd = ../packages/kanata-with-cmd/package.nix;
    terminal-theme-tools = ../packages/terminal-theme-tools/package.nix;
    toshy-runtime = ../packages/toshy-runtime/package.nix;
    uresourced = ../packages/uresourced/package.nix;
  };

  packageArgs = {
    dotfiles-python = {
      inherit (final.unstable) python314Packages;
    };
    ghostty-patched = {
      ghostty = final.unstable.ghostty.override {
        zig_0_15 = final.unstable.zig;
      };
    };
  };

  packages = lib.mapAttrs (
    name: file: final.callPackage file (packageArgs.${name} or { })
  ) packageFiles;
in
packages
// {
  bun2nix = inputs.bun2nix.packages.${final.stdenv.hostPlatform.system}.default;
  gh = final.unstable.gh;
  ghidra-mcp-headless = final.eupkgs.ghidra-mcp-headless;
  hyper-window-tiling-gnome = final.hyper-window-tiling.gnome;
  hyper-window-tiling-kde = final.hyper-window-tiling.kde;
  lldb-mcp-launcher = final.eupkgs.lldb-mcp-launcher;
}
