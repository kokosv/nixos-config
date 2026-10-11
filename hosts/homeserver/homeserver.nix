{ config, inputs, ... }: {
  flake.nixosConfigurations.homeserver = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = (with config.nixos; [
      tailscale
    ]) ++ (with config.homeserver; [
      basePackages
    ]) ++ [
      ./_homeserver/hardware-configuration.nix
      ./_homeserver/disko.nix
      inputs.disko.nixosModules.disko
      {
        networking.hostName = "homeserver";

        networking.useDHCP = false;
        networking.interfaces.ens18.ipv4.addresses = [
          {
            address = "192.168.100.56";
            prefixLength = 24;
          }
        ];
        networking.defaultGateway = "192.168.100.1";
        networking.nameservers = [
          "86.54.11.100"
          "86.54.11.200"
        ];

        boot.loader = {
          systemd-boot.enable = true;
          efi.canTouchEfiVariables = true;
        };

        users.users.root.openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINB4MjILO3RVWMZ7M4PF+tiWcnqSEoNdBMe21uTjUXxS koko@kt480"
        ];

        services.openssh = {
          enable = true;
          listenAddresses = [
            { addr = "100.64.0.5"; }
            { addr = "192.168.100.56"; }
          ];
          settings = {
            PasswordAuthentication = false;
            PermitRootLogin = "prohibit-password";
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
