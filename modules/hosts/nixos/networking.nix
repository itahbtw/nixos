_: {
  flake.modules.nixos.hostFact-nixos-networking =
    { lib, ... }:
    {
      networking = {
        hostName = "nixos";

        networkmanager = {
          enable = true;
        };

        wg-quick = {
          interfaces = {
            vpnbook = {
              # The secrets module replaces this once an encrypted config exists.
              configFile = lib.mkDefault "/etc/wireguard/vpnbook.conf";
              autostart = false;
            };
          };
        };
      };

      # Free routed IPv6 for WARP. The interface stays dormant until
      # scripts/setup-route64-ipv6.sh writes /etc/wireguard/route64.conf.
      services = {
        route64Tunnel = {
          enable = true;
        };
      };
    };
}
