_: {
  flake.modules.nixos.hostFact-nixos-kiwiears = _: {
    services = {
      udev = {
        extraRules = ''
          SUBSYSTEM=="hidraw", ATTRS{idVendor}=="3302", \
            TAG+="uaccess", MODE="0660", RUN{builtin}+="uaccess"
          SUBSYSTEM=="hidraw", ATTRS{idVendor}=="31b2", \
            TAG+="uaccess", MODE="0660", RUN{builtin}+="uaccess"
          SUBSYSTEM=="hidraw", ATTRS{idVendor}=="0bda", \
            ATTRS{idProduct}=="0023", TAG+="uaccess", MODE="0660", \
            RUN{builtin}+="uaccess"
          SUBSYSTEM=="hidraw", ATTRS{idVendor}=="cb01", \
            TAG+="uaccess", MODE="0660", RUN{builtin}+="uaccess"
        '';
      };
    };
  };
}
