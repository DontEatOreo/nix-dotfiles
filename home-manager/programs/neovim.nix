{pkgs, ...}: {
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    viAlias = true;
    vimdiffAlias = true;
    plugins = with pkgs.vimPlugins; [
      # Programming Stuff
      nvim-dap # Launch debugger

      # LSP
      vim-lsp
      vim-lsp-ultisnips
      vim-lsp-ale
      nvim-lsputils
      nvim-lspconfig
      omnisharp-extended-lsp-nvim

      # COC Plugins
      coc-nvim
      coc-explorer
      coc-prettier
      coc-markdownlint
      coc-vimlsp
      coc-python
      coc-ltex # LaTeX

      # CMP
      nvim-cmp
      cmp-path
      cmp-omni
      cmp-nvim-ultisnips

      # General
      vim-airline # Status bar
      vim-signify # Git diff
      vim-polyglot # Syntax highlighting

      # Quality of life
      vim-lastplace # Opens document where you left it
      auto-pairs # Print double quotes/brackets/etc.
      vim-gitgutter # See uncommitted changes of file :GitGutterEnable

      lightline-vim # Info bar at bottom
      indent-blankline-nvim # Indentation lines

      vim-sensible # Sensible defaults
      vim-surround # Surround text with quotes, brackets, etc.
      ReplaceWithRegister # Replace text with contents of register
      fzfWrapper # Fuzzy finder
      deoplete-nvim # Autocompletion
    ];
  };
}
