# Placeholder host for klegion (second laptop).
# Prefixed with _ so it is excluded from auto-import until ready.
#
# TO ACTIVATE:
#   1. Install NixOS on the machine.
#   2. Copy hardware-configuration.nix to hosts/_klegion/hardware-configuration.nix
#   3. Get the host SSH key: cat /etc/ssh/ssh_host_ed25519_key.pub
#   4. Add it as `klegion` in secrets/secrets.nix and re-encrypt:
#        nix run github:ryantm/agenix -- -r
#   5. Rename this file to hosts/klegion.nix (remove the _ prefix).
{ config, inputs, ... }: {
  flake.nixosConfigurations.klegion = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = { inherit inputs; };
    modules =
      (with config.nixos; [
        networking
        hardware
        customization
        keyboardLayout
        displayManager
        i3
        pipewire
        upower
        tailscale
        xsecurelock
        zsh
        environmentalVariables
        services
        configless
        agenix
        # greenclip
        # moonlight
        # trackpoint
        # mpd
      ])
      ++ [
        ./_klegion/hardware-configuration.nix
        {
          networking.hostName = "klegion";

          boot.loader = {
            efi = {
              canTouchEfiVariables = true;
              efiSysMountPoint = "/boot";
            };
            grub = {
              enable = true;
              device = "nodev";
              efiSupport = true;
              timeoutStyle = "hidden";
            };
          };

          users.users.koko = {
            isNormalUser = true;
            description = "koko";
            extraGroups = [
              "networkmanager"
              "wheel"
              "input"
            ];
            # Public keys allowed to SSH into klegion as koko.
            # openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAA..." ];
          };

          nixpkgs.config.allowUnfree = true;

          nix = {
            package = inputs.nixpkgs.legacyPackages.x86_64-linux.nixVersions.stable;
            extraOptions = "experimental-features = nix-command flakes";
            optimise.automatic = true;
          };

          security.rtkit.enable = true;
          system.stateVersion = "26.05";

          services.xserver = {
            enable = true;
            autorun = true;
            displayManager.startx.enable = true;
            desktopManager.wallpaper.mode = "center";
          };

          services.libinput = {
            enable = true;
            touchpad = {
              disableWhileTyping = true;
              naturalScrolling = true;
              tappingDragLock = true;
            };
          };

          services.displayManager.defaultSession = "none+i3";

          services.logind.settings.Login = {
            HandleLidSwitch = "suspend-then-hibernate";
            HandleLidSwitchExternalPower = "suspend-then-hibernate";
            HandleLidSwitchDocked = "suspend-then-hibernate";
          };

          systemd.sleep.settings.Sleep.HibernateDelaySec = "10min";

          # Shared secrets — same encrypted file, each host decrypts with its own key.
          # Both kt480 and klegion must be listed in secrets/secrets.nix for each secret.
          age.secrets.ssh-private-key = {
            file = ../secrets/ssh-private-key.age;
            owner = "koko";
            group = "users";
            mode = "0400";
          };
        }
        inputs.home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "hm-backup";
            extraSpecialArgs = { inherit inputs; };
            users.koko = {
              imports = with config.homeManager; [
                i3Style
                i3Session
                xidlehook
                picom
                polybar
                kitty
                shell
                zsh
                firefox
                rofi
                nvim
                usrDir
                flameshot
                thunderbird
                gtkTheme
                mpv
                git
                sshClient
                btop
                eza
                fzf
                fusuma
                dunst
                direnv
                fastfetch
                lazygit
                configless
                ranger
                pyroclear
              ];
              # SSH uses the agenix-decrypted key from /run/agenix/
              programs.ssh.settings."*".IdentityFile = "/run/agenix/ssh-private-key";
              home = {
                stateVersion = "26.05";
                username = "koko";
                homeDirectory = "/home/koko";
              };
              programs.home-manager.enable = true;
            };
          };
        }
      ];
  };
}
