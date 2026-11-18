{
  config,
  inputs,
  lib,
  ...
}:
let
  allModules = config.flake.modules.nixos;

  # Each host registers a `host-<name>` bundle that imports that machine's facts
  # (`hostFact-<name>-*`). Everything else is a host-agnostic feature and is
  # composed into every host automatically. Attribute names sort alphabetically:
  # never encode precedence in file order, use explicit `imports` or
  # `mkBefore`/`mkAfter` instead.
  isHostBundle = name: lib.hasPrefix "host-" name;
  isHostFact = name: lib.hasPrefix "hostFact-" name;
  isHostOnly = name: isHostBundle name || isHostFact name;

  hostBundles = lib.filterAttrs (name: _: isHostBundle name) allModules;
  commonModules = builtins.attrValues (lib.filterAttrs (name: _: !isHostOnly name) allModules);

  mkHost =
    name: module:
    lib.nameValuePair (lib.removePrefix "host-" name) (
      inputs.nixpkgs.lib.nixosSystem {
        modules = [
          inputs.home-manager.nixosModules.home-manager
          module
        ]
        ++ commonModules;
      }
    );

  hostConfigurations = lib.mapAttrs' mkHost hostBundles;
in
{
  flake = {
    nixosConfigurations = hostConfigurations;

    # Expose reusable modules, but never leak host facts (disk UUIDs, hostname).
    nixosModules = lib.filterAttrs (name: _: !isHostOnly name) allModules;
    homeManagerModules = config.flake.modules.homeManager;

    # Expose each host's toplevel as a flake check so `nix flake check`
    # evaluates (and optionally builds) the full system.
    checks = lib.mkMerge (
      lib.mapAttrsToList (
        name: nixos:
        let
          system = nixos.config.nixpkgs.hostPlatform.system;
        in
        {
          ${system}."nixos-${name}" = nixos.config.system.build.toplevel;
        }
      ) hostConfigurations
    );
  };
}
