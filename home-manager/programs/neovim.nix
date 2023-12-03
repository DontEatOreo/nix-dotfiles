{pkgs, ...}: {
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    viAlias = true;
    vimdiffAlias = true;
    coc = {
      enable = true; # Enable the Conquer of Completion (coc) plugin
      settings = {
        "suggest.noselect" = true; # Do not automatically select the first suggestion
        "suggest.enablePreview" = true; # Enable preview of code suggestion
        "suggest.enablePreselect" = false; # Do not preselect the first suggestion
        "suggest.disableKind" = true; # Disable the kind of suggestion (e.g., method, property)
        languageserver = {
          "command" = "nil";
          "filetypes" = ["nix"];
          "rootPatterns" = ["flake.nix"];
          "settings" = {
            "nil" = {
              "formating" = {"command" = ["alejandra"];};
            };
          };
        };
      };
      pluginConfig = ''
        " Use tab for completion when the popup is visible
        inoremap <expr><tab> pumvisible() ? "\<c-n>" : "\<tab>"

        " Bind explorer to space + e
        nnoremap <space>e :Explore<CR>
      '';
    };
    plugins = with pkgs.vimPlugins; [
      # General
      vim-airline # Lean & mean status/tabline for vim that's light as air
      vim-signify # Show a git diff in the 'gutter' (sign column)
      vim-polyglot # A solid language pack for Vim
      vim-fugitive # A Git wrapper so awesome, it should be illegal
      nerdtree # A tree explorer plugin for vim
      syntastic # Syntax checking hacks for vim

      # COC Plugins
      coc-nvim # Intellisense engine for Vim8 & Neovim
      coc-explorer # File explorer sidebar for coc.nvim
      coc-prettier # Prettier formatter for coc.nvim
      coc-markdownlint # Markdown linting for coc.nvim
      coc-vimlsp # Vim script language server protocol plugin for coc.nvim
      coc-python # Python language server protocol plugin for coc.nvim
      coc-ltex # LaTeX/Markdown language server protocol plugin for coc.nvim

      # Quality of life
      vim-lastplace # Goto the last position when reopening a file
      auto-pairs # Insert or delete brackets, parens, quotes in pair
      indent-blankline-nvim # Indent guides for Neovim
      vim-sensible # Defaults everyone can agree on
      vim-surround # Quoting/parenthesizing made simple
      ReplaceWithRegister # Replace text with contents of register

      # Additional plugins
      deoplete-nvim # Dark powered asynchronous completion framework for neovim
      nvim-treesitter-parsers.vhs # Tree-sitter parsers for Neovim
    ];
  };
}
