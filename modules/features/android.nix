_: {
  flake.modules.homeManager.android =
    { config, ... }:
    {
      home = {
        sessionVariables = {
          ANDROID_HOME = "${config.home.homeDirectory}/Android/Sdk";
          ANDROID_SDK_ROOT = "${config.home.homeDirectory}/Android/Sdk";
        };

        sessionPath = [
          "${config.home.homeDirectory}/Android/Sdk/platform-tools"
          "${config.home.homeDirectory}/Android/Sdk/cmdline-tools/latest/bin"
        ];
      };
    };
}
