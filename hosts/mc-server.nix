{ config, inputs, ... }: {
  flake.nixosConfigurations.mc-server = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      # (with config.mcServer; [ ... ])
      {
        networking.hostName = "mc-server";
        nixpkgs.config.allowUnfree = true;
        nix = {
          package = inputs.nixpkgs.legacyPackages.x86_64-linux.nixVersions.stable;
          extraOptions = "experimental-features = nix-command flakes";
          optimise.automatic = true;
        };
        system.stateVersion = "26.05";
      }
    ];
  };
}
