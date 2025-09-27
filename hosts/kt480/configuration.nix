# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

{
  imports = [ 
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ../../modules/system/default.nix
  ];

  # Enable/disable system modules
  modules = {
    #i3.enable = false;
  };

  # Bootloader.
  boot.loader = {
    grub = {
      enable = true;
      device = "/dev/sda";
      useOSProber = false;
    };
  };

  networking.hostName = "kt480";
  
  # Enables wireless support via wpa_supplicant.
  # networking.wireless.enable = true;
  
  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;
  
  # Enable bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = false;

  # Set your time zone.
  time.timeZone = "Europe/Bucharest";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "bg_BG.UTF-8";
    LC_IDENTIFICATION = "bg_BG.UTF-8";
    LC_MEASUREMENT = "bg_BG.UTF-8";
    LC_MONETARY = "bg_BG.UTF-8";
    LC_NAME = "bg_BG.UTF-8";
    LC_NUMERIC = "bg_BG.UTF-8";
    LC_PAPER = "bg_BG.UTF-8";
    LC_TELEPHONE = "bg_BG.UTF-8";
    LC_TIME = "bg_BG.UTF-8";
  };

  # Configure keymap in X11
  services = {

    xserver = {
      enable = true;
      autorun = true;

      xkb = {
        layout = "us";
        variant = "dvorak";
      };

      displayManager.startx.enable = true;
      windowManager.i3.enable = true;
    };

    libinput = {
      enable = true;
      touchpad.disableWhileTyping = true;
    };

    displayManager = {
      defaultSession = "none+i3";
    };
  };

  # Configure console keymap
  console.keyMap = "dvorak";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users = {
    koko = {
      isNormalUser = true;
      description = "koko";
      extraGroups = [ "networkmanager" "wheel" ];
      packages = with pkgs; [];
      openssh.authorizedKeys.keys = [
     	"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHVgtInaAIzPgkRYnjAyCCiAhIIZj0e3L4Y5ejhXu00l"
      ];
    };

    root = {
      extraGroups = [
        "wheel"
      ];
    };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
 
  # Enable flakes
  nix = {
    package = pkgs.nixVersions.stable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [  

  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh =  {
    enable = true;
    # ports = [ 22 ];
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      KbdInteractiveAuthentication = false;
    };
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?
}
