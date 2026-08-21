{
  inputs,
  lib,
  self,
  ...
}:
{
  imports = [
    inputs.git-hooks-nix.flakeModule
    inputs.treefmt-nix.flakeModule
  ];

  perSystem =
    {
      config,
      pkgs,
      self',
      system,
      ...
    }:
    let
      inherit (pkgs.stdenv.hostPlatform) isDarwin isLinux;

      pythonShell = pkgs.mkShell {
        packages =
          with pkgs;
          [
            unstable.python314
            unstable.uv
          ]
          ++ [ self'.packages.dotfiles-python ];
        env = {
          UV_PYTHON = pkgs.unstable.python314.interpreter;
          UV_PYTHON_DOWNLOADS = "never";
        };
      };

      javascriptShell = pkgs.mkShell {
        packages =
          with pkgs;
          [
            unstable.bun
            unstable.nodejs
          ]
          ++ [ self'.packages.bun2nix ];
      };

      zigShell = pkgs.mkShell {
        packages = [ pkgs.zig_0_16 ];
        inputsFrom = [ self'.packages.terminal-theme-tools ];
      };

      operationsShell = pkgs.mkShell {
        packages =
          with pkgs;
          [
            actionlint
            ansible
            ansible-lint
            check-jsonschema
            cosign
            hadolint
            jq
            npins
            shellcheck
            skopeo
            syft
            yamllint
            yq-go
            zizmor
          ]
          ++ lib.optionals isLinux [ self'.packages.bluebuild-v2 ]
          ++ (
            with pkgs;
            lib.optionals isLinux [
              podman
              podman-compose
            ]
          );
      };

      mkStandaloneNixosModule =
        testModule:
        inputs.nixpkgs.lib.nixosSystem {
          system = null;
          modules = [
            self.nixosModules.default
            {
              boot.isContainer = true;
              nixpkgs.hostPlatform = system;
              local.kde.enable = true;
              system.stateVersion = "26.05";
            }
            testModule
          ];
        };

      standaloneNixosModule = mkStandaloneNixosModule {
        local.user.name = "module-test";
        users = {
          groups.module-test = { };
          users.module-test = {
            group = "module-test";
            isNormalUser = true;
          };
        };
      };

      missingUserMessage = "local.user.name must identify an account declared in users.users.";
      missingUserNixosModule = mkStandaloneNixosModule {
        local.user.name = "missing-user";
      };
      missingUserAssertionPresent = lib.any (
        assertion: !assertion.assertion && assertion.message == missingUserMessage
      ) missingUserNixosModule.config.assertions;

      standaloneNixosModuleCheck =
        assert missingUserAssertionPresent;
        builtins.deepSeq standaloneNixosModule.config.system.build.toplevel.drvPath (
          pkgs.runCommandLocal "nixos-module-evaluation" { } "touch $out"
        );

    in
    {
      checks = {
        inherit (self'.packages) dotfiles-python equicord-settings terminal-theme-tools;
      }
      // lib.optionalAttrs isLinux {
        hyper-window-tiling = self'.packages.hyper-window-tiling-gnome;
        toshy-runtime = self'.packages.toshy-runtime;
      }
      // lib.optionalAttrs isDarwin {
        inherit (self'.packages) fido-phone;
      }
      // lib.optionalAttrs (system == "x86_64-linux") {
        nixos = self.nixosConfigurations.nixos.config.system.build.toplevel;
        nixos-module = standaloneNixosModuleCheck;
      };

      devShells = {
        python = pythonShell;
        javascript = javascriptShell;
        zig = zigShell;
        operations = operationsShell;
        default = pkgs.mkShell {
          inputsFrom = [
            config.pre-commit.devShell
            pythonShell
            javascriptShell
            zigShell
            operationsShell
          ];
          packages = [
            config.treefmt.build.wrapper
          ]
          ++ (with pkgs; [
            git
            just
            quilt
          ]);
          inherit (config.pre-commit) shellHook;
        };
      };

      pre-commit.settings.hooks = {
        actionlint.enable = true;
        ansible-lint = {
          enable = true;
          args = [
            "--offline"
            "ansible"
          ];
          settings.subdir = "ansible";
        };
        biome.enable = true;
        deadnix = {
          enable = true;
          excludes = [
            "hosts/linux/hardware-configuration.nix"
            "packages/hyper-window-tiling/bun.nix"
            "packages/terminal-theme-tools/zig-pkg/.*"
          ];
        };
        statix.enable = true;
        hadolint = {
          enable = true;
          files = "(Dockerfile|Containerfile)$";
        };
        luacheck = {
          enable = true;
          args = [
            "--globals"
            "Command"
            "cx"
            "ya"
            "--"
          ];
        };
        ruff.enable = true;
        rumdl = {
          enable = true;
          excludes = [ "packages/terminal-theme-tools/vendor/tomlc17/PROVENANCE.md" ];
        };
        shellcheck.enable = true;
        treefmt.enable = true;
        yamllint.enable = true;
        zizmor = {
          enable = true;
          args = [
            "--offline"
            "--persona=pedantic"
          ];
        };
      };

      treefmt = {
        projectRootFile = "flake.nix";

        programs = {
          biome = {
            enable = true;
            formatCommand = "format";
            settings = lib.recursiveUpdate (builtins.fromJSON (builtins.readFile ../../biome.jsonc)) {
              # treefmt already walks the Git worktree and passes the selected
              # files explicitly. The generated config lives in the Nix store,
              # where Biome cannot discover this checkout's ignore file.
              vcs.enabled = false;
            };
            validate.enable = false;
          };
          clang-format.enable = true;
          just.enable = true;
          nixfmt.enable = true;
          ruff-format.enable = true;
          rumdl-format.enable = true;
          shfmt = {
            enable = true;
            indent_size = 0;
            simplify = false;
          };
          stylua.enable = true;
          taplo.enable = true;
        };

        settings = {
          excludes = [ "packages/terminal-theme-tools/vendor/**" ];
          formatter = {
            shfmt = {
              includes = lib.mkAfter [
                "dotfiles/dot_local/bin/executable_*"
                "bluebuild/files/system/usr/bin/*"
              ];
              excludes = [
                "dotfiles/dot_local/bin/executable_ghostty-dreamy-swirl.ts"
                "dotfiles/dot_local/bin/executable_helix-rumdl-lsp"
                "bluebuild/files/system/usr/bin/open"
              ];
              options = lib.mkAfter [ "-ci" ];
            };
          };
        };
      };
    };
}
