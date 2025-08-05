inputs: self: super:
let
  kanata = import ./kanata.nix inputs self super;
  yazi = import ./yazi.nix inputs self super;
  vscode = import ./vscode.nix inputs self super;
  ghostty = import ./ghostty.nix inputs self super;
  zellij = import ./zellij.nix inputs self super;
in
kanata // yazi // vscode // ghostty // zellij
