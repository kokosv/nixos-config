{ config, inputs, ... }: {
  flake.nixosConfigurations.vps = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules =
      (with config.vps; [
        ssh
        basePackages
        cloudVmBoot
      ])
      ++ [
        inputs.disko.nixosModules.disko
        ./_vps/disk-config.nix
        {
          networking.hostName = "vps";

          users.users.root.openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFKL/Ju54BCsGZfK5bCpeWl+Zfqu3RK6TfjcSUhKkQiY kaloyansv@gmail.com"
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
