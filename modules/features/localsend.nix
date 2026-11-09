_: {
  flake.modules.nixos.localsend = { pkgs, ... }: {
    programs.localsend.enable = true;
    # Upstream nixpkgs localsend-1.18.0 is broken on Linux: the Flutter
    # binary needs libz.so.1 (zlib) but zlib is not in buildInputs, so
    # autoPatchelf leaves it out of RPATH and the app fails to launch with
    # "error while loading shared libraries: libz.so.1".
    # Adding zlib to buildInputs lets patchelf record its lib dir in RPATH,
    # and runtimeDependencies makes dartFixupHook add it to the wrapper's
    # LD_LIBRARY_PATH (Flutter binaries resolve dart:ffi libs via
    # LD_LIBRARY_PATH, not RPATH).
    programs.localsend.package = pkgs.localsend.overrideAttrs (old: {
      buildInputs = (old.buildInputs or [ ]) ++ [ pkgs.zlib ];
      runtimeDependencies = (old.runtimeDependencies or [ ]) ++ [ pkgs.zlib ];
    });
  };
}
