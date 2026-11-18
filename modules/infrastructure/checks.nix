_: {
  perSystem =
    { pkgs, ... }:
    {
      formatter = pkgs.nixfmt-tree;

      devShells = {
        default = pkgs.mkShell {
          packages = with pkgs; [
            deadnix
            nixd
            nixfmt
            ruff
            shellcheck
            statix
          ];
        };
      };

      checks = {
        statix =
          pkgs.runCommand "statix-check"
            {
              nativeBuildInputs = [ pkgs.statix ];
            }
            ''
              statix check ${../..}
              touch $out
            '';

        deadnix =
          pkgs.runCommand "deadnix-check"
            {
              nativeBuildInputs = [ pkgs.deadnix ];
            }
            ''
              deadnix --fail ${../..}
              touch $out
            '';

        formatting =
          pkgs.runCommand "nixfmt-check"
            {
              nativeBuildInputs = [ pkgs.nixfmt ];
            }
            ''
              find ${../..} -name '*.nix' -print0 | xargs -0 nixfmt --check
              touch $out
            '';

        shellcheck =
          pkgs.runCommand "shellcheck-check"
            {
              nativeBuildInputs = [ pkgs.shellcheck ];
            }
            ''
              shellcheck ${../..}/scripts/*.sh ${../..}/modules/noctalia/*.sh
              touch $out
            '';

        ruff =
          pkgs.runCommand "ruff-check"
            {
              nativeBuildInputs = [ pkgs.ruff ];
            }
            ''
              ruff check --no-cache ${../..}/scripts
              ruff format --check --no-cache ${../..}/scripts
              touch $out
            '';
      };
    };
}
