{ config, inputs, ... }: {
  flake.nixosConfigurations.homeserver = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules =
      (with config.nixos; [
        tailscale
        agenix
      ])
      ++ (with config.homeserver; [
        basePackages
        technitium
        enclosed
        cryptpad
        owncast
        calibre
        mediaStorage
        qbittorrent
      ])
      ++ [
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
            settings = {
              PasswordAuthentication = false;
              PermitRootLogin = "prohibit-password";
            };
          };

          fileSystems."/d02-minecraft" = {
            device = "d02-minecraft";
            fsType = "virtiofs";
          };
          fileSystems."/d03-tv" = {
            device = "d03-tv";
            fsType = "virtiofs";
          };
          fileSystems."/d04-media" = {
            device = "d04-media";
            fsType = "virtiofs";
          };
          fileSystems."/d05-dokumenti" = {
            device = "d05-dokumenti";
            fsType = "virtiofs";
          };
          fileSystems."/d06-knigi" = {
            device = "d06-knigi";
            fsType = "virtiofs";
          };
          fileSystems."/d07-muzika" = {
            device = "d07-muzika";
            fsType = "virtiofs";
          };
          fileSystems."/d08-vid-archiv" = {
            device = "d08-vid-archiv";
            fsType = "virtiofs";
          };
          fileSystems."/d09-kino" = {
            device = "d09-kino";
            fsType = "virtiofs";
          };

          nixpkgs.config.allowUnfree = true;

          nix = {
            package = inputs.nixpkgs.legacyPackages.x86_64-linux.nixVersions.stable;
            extraOptions = "experimental-features = nix-command flakes";
            optimise.automatic = true;
            gc = {
              automatic = true;
              options = "--delete-older-than 15d";
            };
          };

          system.stateVersion = "26.05";
        }
      ];
  };
}
