# NixOS Configuration

> [!Note]
> managed with flake and home-manager.

## Content
- [🚀 Setup](#-setup-from-fresh-install)
- [🖥️ Available Hosts](#️-available-hosts)
- [⚙️ Modules](#️-modules)
- [📁 Structure](#-structure)
- [📝 Notes](#-notes)
- [🔧 Usage](#-usage)
  
## 🚀 Setup from fresh install
```bash
# Open generated config and add git
nano /etc/nixos/configuration.nix

# Rebuild so git is added
sudo nixos-rebuild switch

# Clone the configuration
git clone https://github.com/kokosv/nixos-config.git

# Go to config dir
cd nixos-config

# Switch to this configuration
sudo nixos-rebuild switch --flake .#hostName
```

## 🖥️ Available Hosts
- `kt480` - Main desktop/workstation

## ⚙️ Modules
The configuration uses a modular approach:

- **System modules**: `modules/system/` - System packages and services
- **Home modules**: `modules/home/` - User-specific configurations

## 📁 Structure
```
nixos-config/
├── flake.nix                            # Main flake configuration
├── flake.lock                           # Lock file for reproducible builds
├── hosts/                               # Machine-specific configurations
│   └── kt480/                           # Example host (desktop/laptop)
│       ├── configuration.nix            # System configuration
│       ├── hardware-configuration.nix   # Hardware scan (gitignored)
│       └── home.nix                     # User home-manager configuration
└── modules/                             # Reusable configuration modules
    ├── system/                          # System-level modules
    └── home/                            # Home-manager modules
```

## 📝 Notes
- `hardware-configuration.nix` is gitignored as it's machine-specific
- Secrets and sensitive data are not committed to the repo
- Uses home-manager for user-level configuration management

## 🔧 Usage
### Build for specific host:
```
sudo nixos-rebuild switch --flake .#hostName
```
### Dry-run (see what would change):
```
sudo nixos-rebuild dry-activate --flake .#hostName
```
### Update flake inputs:
```
nix flake update
```
