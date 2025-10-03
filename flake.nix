{
  description = "nixos conf dir";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@
  {
    self,
    nixpkgs,
    home-manager,
    ...
  }: {
    nixosConfigurations = {
      kt480 = nixpkgs.lib.nixosSystem {
	system = "x86_64-linux";
        modules = [ 
	  ./hosts/kt480/configuration.nix
	  home-manager.nixosModules.home-manager {
	    home-manager = {
	      useGlobalPkgs = true;
	      useUserPackages = true;
              backupFileExtension = "hm-backup";
	      users.koko = import ./hosts/kt480/home.nix;
	    };
          }
	];
      };
    };
  };
}
