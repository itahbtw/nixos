_: {
  flake.modules.homeManager.nvim =
    { lib, ... }:
    {
      programs.neovim = {
        enable = true;
        defaultEditor = true;
        initLua = lib.mkAfter (builtins.readFile ./nvim-init.lua);
      };
    };
}
