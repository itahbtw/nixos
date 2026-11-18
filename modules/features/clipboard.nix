_: {
  flake.modules.homeManager.clipboard = _: {
    services = {
      wl-clip-persist = {
        enable = true;
        clipboardType = "both";
        systemdTargets = [
          "graphical-session.target"
        ];
      };

      cliphist = {
        enable = true;
        systemdTargets = [
          "graphical-session.target"
        ];
      };
    };
  };
}
