{ config, ... }:
{
  # Host bundle: the only modules that know this machine's facts (disks, hostname,
  # timezone, user). modules/infrastructure/nixos.nix turns every `host-<name>`
  # key into a nixosConfiguration, so adding `modules/hosts/<name>/default.nix`
  # is enough to support another host.
  flake.modules.nixos.host-nixos = {
    imports = [
      config.flake.modules.nixos.hostFact-nixos-hardware
      config.flake.modules.nixos.hostFact-nixos-boot
      config.flake.modules.nixos.hostFact-nixos-networking
      config.flake.modules.nixos.hostFact-nixos-locale
      config.flake.modules.nixos.hostFact-nixos-user
      config.flake.modules.nixos.hostFact-nixos-firmware
      config.flake.modules.nixos.hostFact-nixos-fprintd
      config.flake.modules.nixos.hostFact-nixos-kiwiears
      config.flake.modules.nixos.hostFact-nixos-brightness
    ];
  };
}
