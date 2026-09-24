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

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # only needed for the very first `nixos-anywhere` install of a new
    # server, not for subsequent `nixos-rebuild switch --target-host` runs
    nixos-anywhere = {
      url = "github:nix-community/nixos-anywhere";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pyroclear = {
      url = "github:shreyanth-sureshkrishnaa/pyroclear";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs =
    inputs:
    let
      lib = inputs.nixpkgs.lib;
      scanDir =
        root:
        lib.filter (
          path:
          lib.all (c: !(lib.hasPrefix "_" c)) (lib.path.subpath.components (lib.path.removePrefix root path))
        ) (lib.filter (lib.hasSuffix ".nix") (lib.filesystem.listFilesRecursive root));
    in
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = (scanDir ./modules) ++ (scanDir ./hosts);

      systems = [ "x86_64-linux" ];
    };
}
