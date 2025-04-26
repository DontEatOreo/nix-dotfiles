{ pkgs, lib, ... }:
let

  language-server = {
    bash-language-server = {
      args = [ "start" ];
      command = lib.getExe pkgs.bash-language-server;
      config.enable = true;
    };
    nil = {
      command = "nil";
      config.nil.formatting.command = [ (lib.getExe pkgs.nixfmt-rfc-style) ];
    };
    ruff = {
      command = lib.getExe pkgs.ruff;
      args = [
        "server"
        "--preview"
      ];
      config = {
        lineLength = 100;
        lint.extendSelect = [ "I" ];
      };
    };
    deno = {
      command = lib.getExe pkgs.deno;
      args = [ "lsp" ];
      config = {
        enable = true;
        lint = true;
        unstable = true;
        format = {
          options = {
            lineWidth = 100;
            indentWidth = 2;
          };
        };
        javascript = {
          format = {
            options = {
              indentWidth = 4;
            };
          };
        };
        typescript = {
          format = {
            options = {
              indentWidth = 4;
            };
          };
        };
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
      config = {
        formatter = {
          alignEntries = true;
          columnWidth = 100;
        };
      };
    };
  };
  language = [
    {
      name = "python";
      auto-format = true;
      language-servers = [ "ruff" ];
    }
    {
      name = "nix";
      auto-format = true;
      language-servers = [ "nil" ];
    }
    {
      name = "bash";
      auto-format = true;
      diagnostic-severity = "warning";
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
    }
    {
      name = "typescript";
      auto-format = true;
      indent = {
        tab-width = 4;
        unit = "    ";
      };
      language-servers = [ "deno" ];
    }
    {
      name = "css";
      auto-format = true;
      language-servers = [ "deno" ];
    }
    {
      name = "json";
      auto-format = true;
      indent = {
        tab-width = 2;
        unit = "  ";
      };
      language-servers = [ "deno" ];
    }
    {
      name = "yaml";
      auto-format = true;
      language-servers = [ "yaml-language-server" ];
    }
    {
      name = "toml";
      auto-format = true;
      language-servers = [ "taplo" ];
    }
  ];
in
{
  programs.helix.languages = { inherit language-server language; };
}
