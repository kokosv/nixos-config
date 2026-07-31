{ config, inputs, ... }: {
  flake.nixosConfigurations.kt480 = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = { inherit inputs; };
    modules = (with config.nixos; [
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
      tailscale
      moonlight
      xsecurelock
      zsh
      environmentalVariables
      services
      configless
      # trackpoint intentionally omitted — not present on kt480
      # mpd intentionally omitted
    ]) ++ [
      ./_kt480/hardware-configuration.nix
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
          extraGroups = [ "networkmanager" "wheel" "input" "adbusers" ];
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
          HandleLidSwitch = "suspend-then-hibernate";
          HandleLidSwitchExternalPower = "suspend-then-hibernate";
          HandleLidSwitchDocked = "suspend-then-hibernate";
        };

        systemd.sleep.settings.Sleep.HibernateDelaySec = "10min";
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
              shell
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
              lazygit
              configless
              ranger
              # clipse intentionally omitted
            ];
            home = {
              stateVersion = "25.05";
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
