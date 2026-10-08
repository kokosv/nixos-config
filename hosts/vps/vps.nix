{ config, inputs, ... }: {
  flake.nixosConfigurations.vps = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules =
      (with config.vps; [
        agenix
        ssh
        basePackages
        cloudVmBoot
        networking
        headscale
        acme
        nginx
        geoip
        anubis
        gatus
        fail2ban
      ])
      ++ [
        inputs.disko.nixosModules.disko
        ./_vps/disko.nix
        {
          networking.hostName = "vps";

          users.users.root.openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINB4MjILO3RVWMZ7M4PF+tiWcnqSEoNdBMe21uTjUXxS koko@kt480"
          ];

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
