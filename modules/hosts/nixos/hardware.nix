_: {
  flake.modules.nixos.hardware =
    {
      config,
      lib,
      modulesPath,
      ...
    }:
    {
      imports = [
        (modulesPath + "/installer/scan/not-detected.nix")
      ];

      boot = {
        initrd.availableKernelModules = [
          "xhci_pci"
          "thunderbolt"
          "nvme"
          "usb_storage"
          "sd_mod"
        ];
        kernelModules = [ "kvm-intel" ];
      };

      fileSystems."/" = {
        device = "/dev/disk/by-uuid/16757e43-8781-43ca-98d8-af261a8861eb";
        fsType = "ext4";
        options = [ "noatime" ];
      };

      fileSystems."/boot" = {
        device = "/dev/disk/by-uuid/535B-B8AD";
        fsType = "vfat";
        options = [
          "fmask=0077"
          "dmask=0077"
        ];
      };

      swapDevices = [
        { device = "/dev/disk/by-uuid/5a411d76-555c-4399-9f41-e4f3939dd193"; }
      ];

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      hardware.cpu.intel.npu.enable = true;
      hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

      system.stateVersion = "26.11";
    };
}
