{ pkgs, lib, ... }:
let
  language = [
    {
      name = "python";
      auto-format = true;
      formatter = {
        args = [
          "format"
          "-"
        ];
        command = lib.getExe pkgs.ruff;
      };
      language-servers = [ "ruff-lsp" ];
    }
    {
      name = "nix";
      auto-format = true;
      formatter.command = lib.getExe pkgs.nixfmt-rfc-style;
    }
    {
      name = "bash";
      auto-format = true;
      diagnostic-severity = "Warning";
      formatter = {
        args = [ "-w" ];
        command = lib.getExe pkgs.shfmt;
      };
      language-servers = [ "bash-language-server" ];
    }
    {
      name = "javascript";
      auto-format = true;
      indent = {
        tab-width = 4;
        unit = "    ";
      };
      language-servers = [ "deno" ];
      formatter = {
        command = lib.getExe pkgs.deno;
        args = [
          "fmt"
          "-"
          "--options-line-width=100"
          "--options-indent-width=4"
        ];
      };
    }
    {
      name = "typescript";
      auto-format = true;
      indent = {
        tab-width = 4;
        unit = "    ";
      };
      language-servers = [ "deno" ];
      formatter = {
        command = lib.getExe pkgs.deno;
        args = [
          "fmt"
          "-"
          "--options-line-width=100"
          "--options-indent-width=4"
        ];
      };
    }
    {
      name = "css";
      auto-format = true;
      language-servers = [ "deno" ];
      formatter = {
        command = lib.getExe pkgs.deno;
        args = [
          "fmt"
          "-"
        ];
      };
    }
    {
      name = "json";
      auto-format = true;
      indent = {
        tab-width = 2;
        unit = "  ";
      };
      language-servers = [ "deno" ];
      formatter = {
        command = lib.getExe pkgs.deno;
        args = [
          "fmt"
          "-"
          "--options-line-width=100"
          "--options-indent-width=2"
        ];
      };
    }
    {
      name = "yaml";
      auto-format = true;
      formatter = {
        command = lib.getExe pkgs.yaml-language-server;
        args = [
          "--format"
          "-"
        ];
      };
      language-servers = [ "yaml-language-server" ];
    }
    {
      name = "toml";
      auto-format = true;
      formatter = {
        command = lib.getExe pkgs.taplo;
        args = [
          "fmt"
          "-"
        ];
      };
      language-servers = [ "taplo" ];
    }
  ];
in
{
  programs.helix.languages = {
    language-server = {
      bash-language-server = {
        args = [ "start" ];
        command = lib.getExe pkgs.bash-language-server;
        config.enable = true;
      };
      nil = {
        command = lib.getExe pkgs.nil;
        config.nil.formatting.command = [ (lib.getExe pkgs.nixfmt-rfc-style) ];
      };
      ruff-lsp = {
        command = lib.getExe pkgs.ruff-lsp;
        config = {
          settings = {
            lint.enable = true;
            organizeImports = true;
            format = {
              enable = true;
              lineLength = 100;
            };
          };
        };
      };
      deno = {
        command = lib.getExe pkgs.deno;
        args = [ "lsp" ];
        config = {
          enable = true;
          lint = true;
          unstable = true;
          suggest = {
            imports = {
              hosts = {
                "https://deno.land" = true;
                "https://cdn.nest.land" = true;
                "https://crux.land" = true;
              };
            };
          };
          inlayHints = {
            enumMemberValues.enabled = true;
            functionLikeReturnTypes.enabled = true;
            parameterNames.enabled = "all";
            parameterTypes.enabled = true;
            propertyDeclarationTypes.enabled = true;
            variableTypes.enabled = true;
          };
        };
      };
      yaml-language-server = {
        command = lib.getExe pkgs.yaml-language-server;
        args = [ "--stdio" ];
        config = {
          yaml = {
            format = {
              enable = true;
            };
            validation = true;
            schemas = {
              https = true;
            };
          };
        };
      };
      taplo = {
        command = lib.getExe pkgs.taplo;
        args = [
          "lsp"
          "stdio"
        ];
        config.formatter = {
          alignEntries = true;
          columnWidth = 100;
        };
      };
    };
    inherit language;
  };
}
