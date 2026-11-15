{
  description = "itah's NixOS configuration (dendritic)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    helium = {
      url = "github:oxcl/nix-flake-helium-browser";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        # Every .nix file under modules/ must be a flake-parts module.
        # import-tree already skips paths containing `/_`; the filter below also
        # skips `modules/lib/` so private helper libraries can live there.
        (inputs.import-tree.filter (path: !(inputs.nixpkgs.lib.hasInfix "/lib/" path)) ./modules)
      ];
    };
}
