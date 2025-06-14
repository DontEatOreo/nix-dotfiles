{ pkgs, lib, ... }:
{
  programs.yazi.settings = {
    mgr = {
      show_hidden = true;
      sort_by = "mtime";
      sort_dir_first = true;
      sort_reverse = true;
    };
    plugin = {
      prepend_fetchers = [
        {
          id = "git";
          name = "*";
          run = "git";
        }
        {
          id = "git";
          name = "*/";
          run = "git";
        }
      ];
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
            (if pkgs.stdenvNoCC.hostPlatform.isDarwin then "open" else "")
            (lib.mkIf pkgs.stdenvNoCC.hostPlatform.isDarwin "open")
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
