{pkgs, ...}: {
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    viAlias = true;
    vimdiffAlias = true;
    plugins = with pkgs.vimPlugins; [
      # General
      vim-airline # Lean & mean status/tabline for vim that's light as air
      vim-signify # Show a git diff in the 'gutter' (sign column)
      vim-polyglot # A solid language pack for Vim
      vim-fugitive # A Git wrapper so awesome, it should be illegal
      nerdtree # A tree explorer plugin for vim

      # Quality of life
      vim-lastplace # Goto the last position when reopening a file
      vim-sensible # Defaults everyone can agree on
      vim-surround # Quoting/parenthesizing made simple

      # Syntax Checking
      syntastic # Syntax checking hacks for vim

      # Code Completion
      deoplete-nvim # Dark powered asynchronous completion framework for neovim
    ];
    extraConfig = builtins.readFile ./config/basic.vim;
  };
}
