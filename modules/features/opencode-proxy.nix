{ ... }:
{
  flake.modules.homeManager.opencodeProxy =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      proxyConfig = "/opt/opencode-unlimited-proxy/stack/config.json";
      apiKeyFile = "${config.xdg.configHome}/opencode/proxy-api-key";
    in
    {
      xdg.configFile."opencode/opencode.json".text = builtins.toJSON {
        "$schema" = "https://opencode.ai/config.json";
        provider.opencode-unlimited-proxy = {
          npm = "@ai-sdk/openai-compatible";
          name = "OpenCode Unlimited Proxy";
          options = {
            baseURL = "http://127.0.0.1:8080/v1";
            apiKey = "{file:${apiKeyFile}}";
          };
          models = builtins.listToAttrs (
            map
              (id: {
                name = id;
                value = { };
              })
              [
                "beam-free"
                "big-pickle"
                "deepseek-v4.1-flash-free"
                "glm-5.3-flash-free"
                "longcat-2.5-preview-free"
                "minimax-m3.1-flash-free"
                "mimo-v2.6-flash-free"
                "nemotron-3.5-lightning-free"
                "nemotron-3.5-super-vl-free"
              ]
          );
        };
      };

      home.activation.opencodeProxyApiKey = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        set -eu
        source="${proxyConfig}"
        target="${apiKeyFile}"
        if [ ! -r "$source" ]; then
          echo "OpenCode proxy config is missing or unreadable: $source" >&2
          exit 1
        fi

        install -d -m 700 "$(dirname "$target")"
        tmp="$target.tmp"
        trap 'rm -f "$tmp"' EXIT
        ${pkgs.jq}/bin/jq -er '.server_keys[0] | select(type == "string" and length > 0)' "$source" > "$tmp"
        chmod 600 "$tmp"
        mv -f "$tmp" "$target"
        trap - EXIT
      '';
    };
}
