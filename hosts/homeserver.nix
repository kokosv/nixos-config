{ config, inputs, ... }: {
  flake.nixosConfigurations.homeserver = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      # (with config.homeserver; [ ... ])
      {
        networking.hostName = "homeserver";
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
