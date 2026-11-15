{
  inputs,
  lib,
  ...
}:
let
  secretFile = name: ../../secrets + "/${name}";
  haveSecret = name: builtins.pathExists (secretFile name);

  # sops-nix is only imported once at least one encrypted secret exists, so a
  # fresh clone (and this migration commit) still evaluates. scripts/
  # migrate-secrets-to-sops.sh creates these files.
  enabled =
    haveSecret "wireguard-route64.conf"
    || haveSecret "wireguard-vpnbook.conf"
    || haveSecret "mariadb-website-password";

  mkSecret = name: target: {
    sopsFile = secretFile name;
    format = "binary";
    path = target;
    mode = "0400";
  };
in
{
  flake.modules.nixos.secrets = {
    imports = lib.optional enabled inputs.sops-nix.nixosModules.sops;

    config = lib.mkMerge [
      {
        services.gnome.gnome-keyring.enable = true;
        security.pam.services.greetd.enableGnomeKeyring = true;
      }

      # Use optionalAttrs rather than mkIf: the `sops' option only exists when
      # the module above is imported, and a false mkIf would still define it.
      (lib.optionalAttrs enabled {
        # The age key is generated once by the migration script and must be
        # backed up; without it the encrypted files in secrets/ cannot be
        # decrypted.
        sops.age.keyFile = "/var/lib/sops-nix/key.txt";

        sops.secrets =
          lib.optionalAttrs (haveSecret "wireguard-route64.conf") {
            "wireguard-route64" = mkSecret "wireguard-route64.conf" "/run/secrets/wireguard-route64.conf";
          }
          // lib.optionalAttrs (haveSecret "wireguard-vpnbook.conf") {
            "wireguard-vpnbook" = mkSecret "wireguard-vpnbook.conf" "/run/secrets/wireguard-vpnbook.conf";
          }
          // lib.optionalAttrs (haveSecret "mariadb-website-password") {
            "mariadb-website-password" =
              mkSecret "mariadb-website-password" "/run/secrets/mariadb-website-password";
          };
      })

      # Point the consumers at the decrypted copies. When a secret is absent the
      # module keeps its previous manual path.
      (lib.optionalAttrs (haveSecret "wireguard-route64.conf") {
        services.route64Tunnel.configFile = "/run/secrets/wireguard-route64.conf";
      })
      (lib.optionalAttrs (haveSecret "wireguard-vpnbook.conf") {
        networking.wg-quick.interfaces.vpnbook.configFile = "/run/secrets/wireguard-vpnbook.conf";
      })
      (lib.optionalAttrs (haveSecret "mariadb-website-password") {
        services.websiteDbPasswordFile = "/run/secrets/mariadb-website-password";
      })
    ];
  };
}
