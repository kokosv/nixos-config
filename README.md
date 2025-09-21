# NixOS Configuration

> [!Note]
> Managed with flakes and home-manager.

## Contents
1. [🚀 Quick Start](#-quick-start)  
2. [📁 Structure](#-structure)  
3. [🔧 Usage](#-usage)  

## 🚀 Quick Start
```
# Clone the configuration
git clone git@github.com:your-username/nixos-config.git
cd nixos-config

# Switch to this configuration
sudo nixos-rebuild switch --flake .#hostname
```

## 📁 Structure

Available Hosts
- kt480 - main desktop

The configuration uses a modular approach:
- System modules: modules/system/ - System packages and services
- Home modules: modules/home/ - User-specific configurations
    
```
nixos-config/
├── flake.nix                            # Main flake configuration
├── flake.lock                           # Lock file for reproducible builds
├── hosts/                               # Machine-specific configurations
│   └── kt480/                           # Example host
│       ├── configuration.nix            # System configuration
│       ├── hardware-configuration.nix   # Hardware scan
│       └── home.nix                     # User home-manager configuration
└── modules/                             # Reusable configuration modules
    ├── system/                          # System-level modules
    └── home/                            # Home-manager modules
```

## 🔧 Usage
Add your host:
1. create new dir in hosts/ with your hostname
2. copy contents of already existing host dir to it
3. add the new host in flake.nix
4. in the new host dir update with the new hostname the following files:
   - configuration.nix
   - home.nix

Build for specific host:
```
sudo nixos-rebuild switch --flake .#hostname
```
Dry-run (see what would change):
```
sudo nixos-rebuild dry-activate --flake .#hostname
```
Update flake inputs:
```
nix flake update
```
