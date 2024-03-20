{
  inputs,
  pkgs,
  ...
}: let
  inherit (inputs.nix-vscode-extensions.extensions.${pkgs.system}.forVSCodeVersion pkgs.vscode.version) vscode-marketplace;
  inherit (inputs.nix-vscode-extensions.extensions.${pkgs.system}.forVSCodeVersion pkgs.vscode.version) vscode-marketplace-release;
in
  with vscode-marketplace;
    [
      # Core Extensions
      editorconfig.editorconfig # Consistent coding styles between developers
      exodiusstudios.comment-anchors # Navigate through your code via comment anchors
      ms-vsliveshare.vsliveshare # Real-time collaborative development
      ms-vscode-remote.vscode-remote-extensionpack # Enables VS Code to be used as a UI when connected to a remote server
      visualstudioexptteam.vscodeintellicode
      vscode-icons-team.vscode-icons # Icons for Visual Studio Code

      # Language Specific Extensions
      ## Bash
      mads-hartmann.bash-ide-vscode # Bash language support

      ## C#
      ms-dotnettools.csharp
      (ms-dotnettools.csdevkit.overrideAttrs (_: {
        sourceRoot = "extension";
        postPatch = with pkgs; ''
          declare patchCommand
          declare add_rpath_command
          if [[ "$(uname)" == "Darwin" ]]; then
            patchCommand="install_name_tool"
            add_rpath_command="-add_rpath"
          else
            patchCommand="patchelf"
            add_rpath_command="--set-rpath"
          fi

          patchelf_add_icu_as_needed() {
            declare elf="''${1?}"
            declare icu_major_v="${lib.head (lib.splitVersion (lib.getVersion icu.name))}"
            for icu_lib in icui18n icuuc icudata; do
              patchelf --add-needed "lib''${icu_lib}.so.$icu_major_v" "$elf"
            done
          }
          patchelf_common() {
            declare elf="''${1?}"

            chmod +x "$elf"
            patchelf_add_icu_as_needed "$elf"
            patchelf --add-needed "libssl.so" "$elf"
            patchelf --add-needed "libz.so.1" "$elf"
            patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
              --set-rpath "${lib.makeLibraryPath [stdenv.cc.cc openssl zlib icu.out]}:\$ORIGIN" \
              "$elf"
          }

          sed -i -E -e 's/(e.extensionPath,"cache")/require("os").homedir(),".cache","Microsoft", "csdevkit","cache"/g' "$PWD/dist/extension.js"
          sed -i -E -e 's/o\.chmod/console.log/g' "$PWD/dist/extension.js"

          declare platform
          case "${stdenv.system}" in
            "x86_64-linux") platform="linux-x64" ;;
            "aarch64-linux") platform="linux-arm64" ;;
            "x86_64-darwin") platform="darwin-x64" ;;
            "aarch64-darwin") platform="darwin-arm64" ;;
            *) echo "Unsupported platform: ${stdenv.system}"; exit 1 ;;
          esac

          declare new_rpath="${lib.makeLibraryPath [stdenv.cc.cc openssl zlib icu.out]}:\$ORIGIN"

          declare base_path="./components/vs-green-server/platforms/$platform/node_modules"

          $patchCommand $add_rpath_command "$new_rpath" "$base_path/@microsoft/visualstudio-server.$platform/Microsoft.VisualStudio.Code.Server"
          $patchCommand $add_rpath_command "$new_rpath" "$base_path/@microsoft/servicehub-controller-net60.$platform/Microsoft.ServiceHub.Controller"
          $patchCommand $add_rpath_command "$new_rpath" "$base_path/@microsoft/visualstudio-code-servicehost.$platform/Microsoft.VisualStudio.Code.ServiceHost"
          $patchCommand $add_rpath_command "$new_rpath" "$base_path/@microsoft/visualstudio-reliability-monitor.$platform/Microsoft.VisualStudio.Reliability.Monitor"
        '';
      }))
      # Cannot activate the 'C# Dev Kit' extension because it depends on the '.NET Install Tool' extension from 'Microsoft', which is not installed. Would you like to install the extension and reload the window?
      (ms-dotnettools.vscode-dotnet-runtime.overrideAttrs (_: {
        sourceRoot = "extension";
        postPatch = ''
          chmod +x "$PWD/dist/install scripts/dotnet-install.sh"
        '';
      }))
      (ms-dotnettools.vscodeintellicode-csharp.overrideAttrs (_: {sourceRoot = "extension";}))

      ## Java
      redhat.java # Java language support
      vscjava.vscode-java-pack # Java Extension Pack

      ## JS & TS
      dbaeumer.vscode-eslint # ESLint support
      gregorbiswanger.json2ts # Convert JSON objects to TypeScript interfaces
      mgmcdermott.vscode-language-babel # Babel language support
      ms-vscode.vscode-typescript-next # TypeScript language support
      steoates.autoimport # Auto import for JavaScript and TypeScript

      ## Nix
      bbenoist.nix # Nix language support
      jnoortheen.nix-ide # Nix IDE features

      ## Python
      ms-python.python # Python language support
      ms-python.vscode-pylance # Python language server
      ms-python.black-formatter # Format Python Code

      ## VIM
      xadillax.viml

      # Text Editing and Documentation
      aykutsarac.jsoncrack-vscode # JSONCrack support
      davidanson.vscode-markdownlint # Linting for Markdown files
      james-yu.latex-workshop # LaTeX support
      redhat.vscode-xml # XML language support

      # Themes
      github.github-vscode-theme # GitHub's VS Code theme

      # Utilities
      esbenp.prettier-vscode # Code formatting with Prettier
      kamadorueda.alejandra # Opinionated Nix Formatter
      mkhl.direnv # Direnv support
      oderwat.indent-rainbow # Colorful indentation
      ryu1kn.partial-diff # Compare (diff) text selections within a file
    ]
    ++ (with vscode-marketplace-release; [
      github.copilot # AI-powered coding assistant
      github.copilot-chat # Chat with GitHub Copilot
    ])
