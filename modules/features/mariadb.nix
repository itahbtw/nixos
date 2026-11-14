_: {
  flake.modules.nixos.mariadb = { pkgs, ... }: {
    services.mysql = {
      enable = true;
      package = pkgs.mariadb;

      # Local development only: never listen on the network.
      settings.mysqld = {
        "bind-address" = "127.0.0.1";
      };

      ensureDatabases = [
        "dev"
        "website"
      ];

      # Runs once, when the data directory is first initialised.
      # Only creates the `dev` database; no credentials are stored here.
      initialScript = ../mariadb/init.sql;
    };

    # Sets the itah user's password for the website database from a root-only file.
    # The password is intentionally not stored in this repo.
    # Create it once with: sudo install -m 0400 /dev/null /root/mariadb-website-password
    # then write a strong password into that file.
    systemd.services.mariadb-website-password = {
      description = "Set MariaDB password for itah user";
      after = [ "mysql.service" ];
      wants = [ "mysql.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "root";
        UMask = "0077";
        ExecStart = pkgs.writeShellScript "mariadb-website-password" ''
          set -eu
          password_file=/root/mariadb-website-password
          if [ ! -r "$password_file" ]; then
            echo "Missing $password_file" >&2
            exit 1
          fi
          pw=$(cat "$password_file")
          if [ -z "$pw" ]; then
            echo "Empty password in $password_file" >&2
            exit 1
          fi
          ${pkgs.mariadb}/bin/mysql -u root <<SQL
          CREATE USER IF NOT EXISTS 'itah'@'localhost' IDENTIFIED BY '$pw';
          ALTER USER 'itah'@'localhost' IDENTIFIED BY '$pw';
          CREATE USER IF NOT EXISTS 'itah'@'127.0.0.1' IDENTIFIED BY '$pw';
          ALTER USER 'itah'@'127.0.0.1' IDENTIFIED BY '$pw';
          GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, ALTER, DROP, INDEX,
            REFERENCES, CREATE TEMPORARY TABLES, LOCK TABLES, TRIGGER,
            CREATE VIEW, SHOW VIEW ON website.* TO 'itah'@'localhost';
          GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, ALTER, DROP, INDEX,
            REFERENCES, CREATE TEMPORARY TABLES, LOCK TABLES, TRIGGER,
            CREATE VIEW, SHOW VIEW ON website.* TO 'itah'@'127.0.0.1';
          FLUSH PRIVILEGES;
          SQL
        '';
      };
    };
  };
}
