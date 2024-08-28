{ pkgs, lib, ... }:
{
  programs.yazi.settings = {
    manager = {
      show_hidden = true;
      sort_by = "modified";
      sort_dir_first = true;
      sort_reverse = true;
    };
    open = {
      rules = [
        # Folder
        {
          name = "*/";
          use = [
            "edit"
            "open"
            "reveal"
          ];
        }
        # Text
        {
          mime = "text/*";
          use = [
            "edit"
            "reveal"
          ];
        }
        # Image
        {
          mime = "image/*";
          use = [
            "open"
            "reveal"
          ];
        }
        # Media
        {
          mime = "{audio,video}/*";
          use = [
            (if pkgs.stdenvNoCC.isDarwin then "open" else "")
            (lib.mkIf pkgs.stdenvNoCC.isDarwin "open")
            "reveal"
          ];
        }
        # Archive
        {
          mime = "application/{,g}zip";
          use = [
            "unzip"
            "reveal"
          ];
        }
        {
          mime = "application/x-{tar,bzip*,7z-compressed,xz,rar}";
          use = [
            "extract"
            "reveal"
          ];
        }
        # JSON
        {
          mime = "application/{json,x-ndjson}";
          use = [
            "edit"
            "reveal"
          ];
        }
        {
          mime = "*/javascript";
          use = [
            "edit"
            "reveal"
          ];
        }
        # Empty file
        {
          mime = "inode/x-empty";
          use = [
            "edit"
            "reveal"
          ];
        }
        # Fallback
        {
          name = "*";
          use = [
            "open"
            "reveal"
          ];
        }
      ];
    };
  };
}
