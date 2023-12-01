{pkgs, ...}: {
  programs.chromium = {
    enable = true;
    package = pkgs.brave;
    dictionaries = with pkgs; [hunspellDictsChromium.en_US];
    extensions = [
      {id = "cjpalhdlnbpafiamejdnhcphjbkeiagm";} # Ublock Origin
      {id = "mnjggcdmjocbbbhaepdhchncahnbgone";} # Sponsor Block
      {id = "enamippconapkdmgfgjchkhakpfinmaj";} # Dearrow
      {id = "gebbhagfogifgggkldgodflihgfeippi";} # Return YT Dislikes
      {id = "pobhoodpcipjmedfenaigbeloiidbflp";} # Minimal Twitta Theme
    ];
  };
}
