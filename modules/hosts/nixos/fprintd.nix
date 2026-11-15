_: {
  flake.modules.nixos.hostFact-nixos-fprintd = _: {
    services.fprintd.enable = true;

    # greetd authenticates by `substack login`, so login's PAM stack (and its
    # `pam_fprintd` line) is what the greeter offers. Fingerprint auth is
    # `sufficient`, so it succeeds without ever passing a password to
    # pam_gnome_keyring -> the login keyring stays locked after a fingerprint
    # login. Disable fingerprint on login only; sudo, polkit and lock screens
    # keep it (they have their own PAM services).
    security.pam.services.login.fprintAuth = false;
  };
}
