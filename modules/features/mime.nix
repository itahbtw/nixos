_: {
  flake.modules.nixos.mime = _: {
    # Keep the broad defaults here, but avoid a `text/*` glob: the NixOS module
    # expands globs using shared-mime-info order, so `text/*` emits
    # `text/html=nvim` before the explicit `text/html=firefox` line and
    # xdg-mime takes the first match. `text/x-*` covers source files without
    # touching `text/html`.
    xdg.mime.defaultApplications = {
      "text/plain" = "nvim.desktop";
      "text/markdown" = "nvim.desktop";
      "text/csv" = "nvim.desktop";
      "text/x-*" = "nvim.desktop";
      "text/html" = "firefox.desktop";
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
      "application/pdf" = "org.pwmt.zathura.desktop";
      "image/*" = "imv-dir.desktop";
      "audio/*" = "mpv.desktop";
      "video/*" = "mpv.desktop";
      "inode/directory" = "yazi.desktop";
      "application/zip" = "yazi.desktop";
      "application/gzip" = "yazi.desktop";
      "application/*zip*" = "yazi.desktop";
      "application/x-tar*" = "yazi.desktop";
      "application/x-7z*" = "yazi.desktop";
      "application/x-rar*" = "yazi.desktop";
      "application/vnd.rar" = "yazi.desktop";
      "application/x-bzip*" = "yazi.desktop";
      "application/x-xz*" = "yazi.desktop";
      "application/x-zstd*" = "yazi.desktop";
      "application/x-lzma*" = "yazi.desktop";
      "application/x-cpio*" = "yazi.desktop";
      "application/x-arj" = "yazi.desktop";
      "application/x-compress*" = "yazi.desktop";
    };
  };
}
