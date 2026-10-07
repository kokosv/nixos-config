{ config, inputs, ... }: {
  flake.nixosConfigurations.kt480 = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = { inherit inputs; };
    modules =
      (with config.nixos; [
        networking
        sshServer
        hardware
        customization
        keyboardLayout
        displayManager
        i3
        pipewire
        upower
        greenclip
        smartcard
        tailscale
        moonlight
        xsecurelock
        zsh
        environmentalVariables
        services
        configless
        agenix
        # trackpoint
        # mpd
      ])
      ++ [
        ./_kt480/hardware-configuration.nix
        ./_kt480/disko.nix
        inputs.disko.nixosModules.disko
        {
          networking.hostName = "kt480";

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
              "adbusers"
            ];
            # Public keys allowed to SSH into kt480 as koko.
            # openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAA..." ];
          };
          users.users.root.extraGroups = [ "wheel" ];

          nixpkgs.config.allowUnfree = true;

          nix = {
            package = inputs.nixpkgs.legacyPackages.x86_64-linux.nixVersions.stable;
            extraOptions = "experimental-features = nix-command flakes";
            optimise.automatic = true;
          };

          security.rtkit.enable = true;
          system.stateVersion = "25.05";

          environment.systemPackages = [ ];

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
            HandleLidSwitch = "suspend";
            HandleLidSwitchExternalPower = "suspend";
            HandleLidSwitchDocked = "suspend";
          };

          zramSwap.enable = true;

          # Root needs the SSH key too — sudo nixos-rebuild --target-host runs SSH as root,
          # which ignores koko's ~/.ssh/config. This adds the identity to /etc/ssh/ssh_config
          # (system-wide fallback), so root picks it up without extra flags.
          programs.ssh.extraConfig = ''
            Host *
              IdentityFile /run/agenix/ssh-private-key
          '';

          # Shared secrets — same encrypted file, each host decrypts with its own key.
          # Both kt480 and klegion must be listed in secrets/secrets.nix for each secret.
          # Create the file first: nix run github:ryantm/agenix -- -e secrets/ssh-private-key.age
          age.secrets.ssh-private-key = {
            file = ../../secrets/ssh-private-key.age;
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
                picom
                polybar
                kitty
                zsh
                firefox
                rofi
                nvim
                usrDir
                gromitMpx
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
                khal
                dunst
                direnv
                fastfetch
                fetch
                lazygit
                configless
                ranger
                pyroclear
                # clipse
              ];
              home = {
                stateVersion = "25.05";
                username = "koko";
                homeDirectory = "/home/koko";
              };
              # SSH uses the agenix-decrypted key from /run/agenix/
              programs.ssh.settings."*".IdentityFile = "/run/agenix/ssh-private-key";
              programs.home-manager.enable = true;
            };
          };
        }
      ];
  };
}
