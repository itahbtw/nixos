_: {
  flake.modules.nixos.ocr =
    { pkgs, ... }:
    {
      environment = {
        systemPackages = with pkgs; [
          (tesseract.override {
            enableLanguages = [
              "eng"
              "ind"
            ];
          })
          grim
          slurp
          (writeShellApplication {
            name = "ocr-region";
            runtimeInputs = [
              grim
              slurp
              tesseract
              wl-clipboard
              libnotify
            ];
            text = ''
              tmp="$(mktemp --suffix=.png)"
              trap 'rm -f "$tmp"' EXIT
              if ! grim -g "$(slurp)" "$tmp"; then
                exit 1
              fi
              tesseract "$tmp" stdout 2>/dev/null | wl-copy
              notify-send "OCR" "Text copied to clipboard" 2>/dev/null || true
            '';
          })
        ];
      };
    };
}
