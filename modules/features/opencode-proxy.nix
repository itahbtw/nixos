_: {
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
      syncScript = ../../scripts/opencode-proxy-sync.py;
      fallbackModels = [
        "beam-free"
        "big-pickle"
        "deepseek-v4.1-flash-free"
        "flint-40b-free"
        "glm-5.3-flash-free"
        "iceman-free"
        "inkling-2-small-free"
        "longcat-2.5-free"
        "mimo-v2.6-flash-free"
        "minimax-m3.1-flash-free"
        "nemotron-3.5-lightning-free"
        "nemotron-3.5-super-vl-free"
      ];
      baseConfig = {
        "$schema" = "https://opencode.ai/config.json";
        provider.opencode-unlimited-proxy = {
          npm = "@ai-sdk/openai-compatible";
          name = "OpenCode Unlimited Proxy";
          options = {
            baseURL = "http://127.0.0.1:8080/v1";
            apiKey = "{file:${apiKeyFile}}";
          };
          models = builtins.listToAttrs (
            map (id: {
              name = id;
              value = { };
            }) fallbackModels
          );
        };
      };
    in
    {
      # The proxy's model catalog is runtime data, so keep only the static
      # provider settings here and regenerate opencode.json on every activation.
      xdg.configFile."opencode/opencode-proxy-base.json".text = builtins.toJSON baseConfig;

      # The proxy is optional: a missing checkout must not break every Home
      # Manager activation. Leave any existing key in place and warn instead.
      home.activation.opencodeProxyApiKey = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        set -eu
        proxy_config="${proxyConfig}"
        target="${apiKeyFile}"
        if [ ! -r "$proxy_config" ]; then
          echo "OpenCode proxy config missing ($proxy_config); skipping key sync." >&2
          exit 0
        fi

        install -d -m 700 "$(dirname "$target")"
        tmp="$target.tmp"
        trap 'rm -f "$tmp"' EXIT
        if ! ${pkgs.jq}/bin/jq -er '.server_keys[0] | select(type == "string" and length > 0)' "$proxy_config" > "$tmp"; then
          echo "OpenCode proxy config has no usable server key; skipping." >&2
          exit 0
        fi
        chmod 600 "$tmp"
        mv -f "$tmp" "$target"
        trap - EXIT
      '';

      home.activation.opencodeProxyConfig = lib.hm.dag.entryAfter [ "opencodeProxyApiKey" ] ''
        ${pkgs.python3}/bin/python3 ${lib.escapeShellArg (toString syncScript)} || true
      '';
    };
}
