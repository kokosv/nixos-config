{
  description = "nixos conf dir";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim/nixos-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    ...
  }
  @inputs:
  let
    system = "x86_64-linux";
    lib = nixpkgs.lib;
    extraSpecialArgs = { inherit system inputs; };
    specialArgs = { inherit system inputs; };
  in {
    nixosConfigurations = {
      kt480 = lib.nixosSystem {
        modules = [
	  ./hosts/kt480/configuration.nix
	  home-manager.nixosModules.home-manager {
	    home-manager = {
	      inherit extraSpecialArgs;
	      useGlobalPkgs = true;
	      useUserPackages = true;
              backupFileExtension = "hm-backup";
	      users.koko = import ./hosts/kt480/home.nix;
	    };
          }
	];
	specialArgs = specialArgs;
      };
    };
  };
}
