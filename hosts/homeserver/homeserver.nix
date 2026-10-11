{ config, inputs, ... }: {
  flake.nixosConfigurations.homeserver = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      ./_homeserver/hardware-configuration.nix
      ./_homeserver/disko.nix
      inputs.disko.nixosModules.disko
      {
        networking.hostName = "homeserver";

        boot.loader = {
          systemd-boot.enable = true;
          efi.canTouchEfiVariables = true;
        };

        users.users.root.openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINB4MjILO3RVWMZ7M4PF+tiWcnqSEoNdBMe21uTjUXxS koko@kt480"
        ];

        services.openssh = {
          enable = true;
          settings = {
            PasswordAuthentication = false;
            PermitRootLogin = "yes";
          };
        };

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
