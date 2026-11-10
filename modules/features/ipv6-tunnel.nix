{ ... }:
{
  flake.modules.nixos.ipv6Tunnel =
    { config, lib, ... }:
    let
      cfg = config.services.route64Tunnel;
    in
    {
      options.services.route64Tunnel = {
        enable = lib.mkEnableOption "the route64 WireGuard IPv6 tunnel";

        configFile = lib.mkOption {
          type = lib.types.str;
          default = "/etc/wireguard/route64.conf";
          description = ''
            WireGuard configuration written by
            `scripts/setup-route64-ipv6.sh`. It is read at boot, so the private
            key stays out of the Nix store.
          '';
        };
      };

      config = lib.mkIf cfg.enable {
        # WARP binds source addresses from the routed prefix. Those addresses
        # are delivered by the tunnel but never assigned to an interface, so the
        # kernel has to permit binding them.
        boot.kernel.sysctl."net.ipv6.ip_nonlocal_bind" = 1;

        networking.wg-quick.interfaces.route64 = {
          configFile = cfg.configFile;
          autostart = true;
        };

        # Bring the tunnel up before Docker restores the proxy container, so the
        # engine can bind its WARP sources from the routed prefix.
        systemd.services.docker = lib.mkIf config.virtualisation.docker.enable {
          wants = [ "wg-quick-route64.service" ];
          after = [ "wg-quick-route64.service" ];
        };

        # Stay inactive until the tunnel has been provisioned, so an activation
        # before the route64 account exists does not leave a failed unit.
        systemd.services."wg-quick-route64".unitConfig.ConditionPathExists = cfg.configFile;
      };
    };
}
