_: {
  flake.modules.nixos.hostFact-nixos-firmware = _: {
    services = {
      fwupd = {
        enable = true;
      };

      thermald = {
        enable = true;
      };
    };

    hardware = {
      enableRedistributableFirmware = true;
    };
  };
}
