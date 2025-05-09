{ pkgs, lib, ... }:
let
  language-server = {
    bash-language-server = {
      args = [ "start" ];
      command = "bash-language-server";
      config.enable = true;
    };
    nil = {
      command = "nil";
      config.nil.formatting.command = [ "nixfmt" ];
    };
    ruff = {
      command = "ruff";
      args = lib.splitString " " "server --preview";
      config.lineLength = 100;
      config.lint.extendSelect = [ "I" ];
    };
    deno = {
      command = "deno";
      args = [ "lsp" ];
      config = {
        enable = true;
        lint = true;
        unstable = true;
        format.options.lineWidth = 100;
        format.options.indentWidth = 2;
        javascript.format.options.indentWidth = 4;
        typescript.format.options.indentWidth = 4;
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
      command = "yaml-language-server";
      args = [ "--stdio" ];
      config = {
        yaml = {
          format.enable = true;
          validation = true;
          schemas.https = true;
        };
      };
    };
    taplo = {
      command = "taplo";
      args = lib.splitString " " "lsp stdio";
      config.formatter.alignEntries = true;
      config.formatter.columnWidth = 100;
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
      formatter.args = [ "-w" ];
      formatter.command = "shfmt";
      language-servers = [ "bash-language-server" ];
    }
    {
      name = "javascript";
      auto-format = true;
      indent.tab-width = 4;
      indent.unit = "    ";
      language-servers = [ "deno" ];
    }
    {
      name = "typescript";
      auto-format = true;
      indent.tab-width = 4;
      indent.unit = "    ";
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
      indent.tab-width = 2;
      indent.unit = "  ";
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
  home.packages = builtins.attrValues {
    inherit (pkgs)
      deno # JS, TS, CSS
      ruff # Python
      shfmt # Bash
      taplo # TOML
      yaml-language-server
      ;
  };
  programs.helix.languages = { inherit language-server language; };
}
