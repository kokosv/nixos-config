{
  description = "nixos conf dir";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim.url = "github:nix-community/nixvim";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
  };

  outputs = inputs:
    let
      lib = inputs.nixpkgs.lib;
      modulesPath = ./modules;
    in
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = lib.filter
        (path: lib.all
          (c: !(lib.hasPrefix "_" c))
          (lib.path.subpath.components (lib.path.removePrefix modulesPath path)))
        (lib.filter (lib.hasSuffix ".nix")
          (lib.filesystem.listFilesRecursive modulesPath));

      systems = [ "x86_64-linux" ];
    };
}
