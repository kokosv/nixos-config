# Config Structure

This config uses the **dendritic pattern** with **flake-parts**. The core idea: every `.nix` file under `modules/` is an independent flake-parts module that is auto-imported. No central aggregator file exists. Adding a feature means creating one file.

---

## Directory layout

```
flake.nix                          — entry point, auto-imports everything in modules/
modules/
  nixos/                           — system-level feature modules (NixOS options)
    networking.nix
    ssh-server.nix
    keyboard-layout.nix
    _keyboard/                     — non-.nix support file (excluded from auto-import)
      bg-phonetic-dvorak
    ...
  home/                            — user-level feature modules (home-manager options)
    btop.nix
    firefox.nix
    nvim.nix
    _nvim/                         — sub-files for nvim (excluded from auto-import)
      config/plugins/kickstart/
    zsh.nix
    _zsh/                          — sub-files for zsh (excluded from auto-import)
      config/
    ...
  hosts/
    kt480.nix                      — assembles the final nixosConfiguration for this machine
    _kt480/                        — host-specific files excluded from auto-import
      hardware-configuration.nix
```

The `hosts/kt480/` directory at the repo root (old location) is no longer used.

---

## The `_` prefix rule

Any file or directory whose name starts with `_` is **excluded from auto-import**. Use this for:

- Files that are not flake-parts modules (e.g., raw XKB symbols, zsh scripts)
- Sub-files that belong to a parent module and get imported manually by it
- Host-specific hardware configs

Everything else under `modules/` with a `.nix` extension is automatically picked up.

---

## How each file is structured

### `modules/nixos/*.nix` — system feature

Each file declares one flake-parts option of type `deferredModule`, then sets it to a NixOS module.

```nix
# modules/nixos/ssh-server.nix
{ lib, ... }: {
  options.nixos.sshServer = lib.mkOption { type = lib.types.deferredModule; };

  config.nixos.sshServer = {
    services.openssh = {
      enable = true;
      settings.PasswordAuthentication = false;
    };
  };
}
```

The option name is **camelCase** so it can be used with `with config.nixos;` in the host file without quoting.

If the module body needs `pkgs` or NixOS's own `config`, write it as a module function:

```nix
config.nixos.myFeature = { pkgs, config, ... }: {
  environment.systemPackages = [ pkgs.something ];
};
```

### `modules/home/*.nix` — user feature

Same pattern, but under `homeManager.*` and the value is a home-manager module:

```nix
# modules/home/btop.nix
{ lib, ... }: {
  options.homeManager.btop = lib.mkOption { type = lib.types.deferredModule; };

  config.homeManager.btop = { pkgs, ... }: {
    home.packages = with pkgs; [ btop ];
    programs.btop.enable = true;
  };
}
```

When the module body needs home-manager's `config` (e.g., referencing `config.home.homeDirectory` or `config.lib.formats.rasi`), it must be a module function so the args come from home-manager's module system:

```nix
config.homeManager.myThing = { pkgs, config, lib, ... }: {
  xdg.userDirs.documents = "${config.home.homeDirectory}/doc";
};
```

### `modules/hosts/kt480.nix` — host assembly

This is where the machine is actually built. It picks which features to include by referencing the options declared by the individual modules:

```nix
{ config, inputs, ... }: {
  flake.nixosConfigurations.kt480 = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = { inherit inputs; };
    modules = (with config.nixos; [
      networking sshServer hardware customization keyboardLayout
      displayManager i3 pipewire upower greenclip tailscale moonlight
      xsecurelock zsh environmentalVariables services configless
      # trackpoint intentionally omitted — not present on kt480
    ]) ++ [
      ./_kt480/hardware-configuration.nix
      { networking.hostName = "kt480"; ... }
      inputs.home-manager.nixosModules.home-manager
      {
        home-manager.users.koko = {
          imports = with config.homeManager; [
            i3Style i3Session picom polybar kitty shell zsh
            firefox rofi nvim usrDir gromitMpx flameshot
            thunderbird gtkTheme mpv git sshClient btop eza
            fzf fusuma khal dunst direnv fastfetch lazygit
            configless ranger
            # clipse intentionally omitted
          ];
          home = { stateVersion = "25.05"; username = "koko"; homeDirectory = "/home/koko"; };
          programs.home-manager.enable = true;
        };
      }
    ];
  };
}
```

Features are included or excluded by putting them in or leaving them out of these lists — no `enable = false` anywhere.

---

## Adding a new feature

### Example: a systemd user service that syncs something on login

**Step 1 — create `modules/home/sync-on-login.nix`:**

```nix
{ lib, ... }: {
  options.homeManager.syncOnLogin = lib.mkOption { type = lib.types.deferredModule; };

  config.homeManager.syncOnLogin = { pkgs, ... }: {
    systemd.user.services.sync-on-login = {
      Unit.Description = "Sync files on login";
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.rsync}/bin/rsync -av ~/src/ ~/backup/";
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}
```

**Step 2 — add it to the host in `modules/hosts/kt480.nix`:**

```nix
imports = with config.homeManager; [
  ...
  syncOnLogin   # ← add here
];
```

That is the entire change. No aggregator file, no option declaration elsewhere, no enable flag.

### Example: a NixOS system service (e.g., a custom daemon)

**Step 1 — create `modules/nixos/my-daemon.nix`:**

```nix
{ lib, ... }: {
  options.nixos.myDaemon = lib.mkOption { type = lib.types.deferredModule; };

  config.nixos.myDaemon = { pkgs, ... }: {
    systemd.services.my-daemon = {
      description = "My custom daemon";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.my-daemon}/bin/my-daemon";
        Restart = "on-failure";
      };
    };
    environment.systemPackages = [ pkgs.my-daemon ];
  };
}
```

**Step 2 — add it to `modules/hosts/kt480.nix`:**

```nix
modules = (with config.nixos; [
  ...
  myDaemon   # ← add here
]) ++ [ ... ];
```

Done.

---

## Sub-files for complex modules

When a module is large and needs to split logic across multiple files (e.g., nvim plugins, zsh config), the sub-files go in a `_`-prefixed directory next to the main file so they are excluded from auto-import:

```
modules/home/
  nvim.nix          ← flake-parts module, imports the sub-files
  _nvim/
    config/
      plugins/
        kickstart/
          lsp.nix   ← plain home-manager module, NOT a flake-parts module
          ...
```

The main `nvim.nix` manually imports them in its deferredModule value:

```nix
config.homeManager.nvim = { pkgs, inputs, ... }: {
  imports = [
    inputs.nixvim.homeModules.nixvim
    ./_nvim/config/plugins/kickstart/lsp.nix
    ...
  ];
  programs.nixvim = { ... };
};
```

Sub-files under `_` are **regular NixOS/home-manager modules**, not flake-parts modules. They do not declare `options.nixos.*` or `options.homeManager.*`.

---

## What changed vs the old approach

### Old approach

```
modules/
  system/
    default.nix       ← declared ALL options: modules.ssh-server.enable, modules.networking.enable, ...
    ssh-server.nix    ← checked cfg.enable, applied config conditionally
    networking.nix
    ...
  home/
    default.nix       ← declared ALL options: home.modules.firefox.enable, ...
    firefox.nix       ← checked cfg.enable
    ...
hosts/kt480/
  configuration.nix   ← imported system/default.nix, set modules.trackpoint.enable = false
  home.nix            ← imported home/default.nix, set home.modules.clipse.enable = false
```

### New approach (dendritic)

```
modules/
  nixos/ssh-server.nix    ← self-contained: declares option + sets it
  home/firefox.nix        ← self-contained: declares option + sets it
  hosts/kt480.nix         ← picks which options to use
```

### Why it is better

**1. Adding a module touches one file, not three.**
Old: create the module file, add its import to `default.nix`, declare `enable` option in `default.nix`. New: create the module file. Done.

**2. No enable options means no dead state.**
Old: a module could be declared but disabled (`enable = false`), meaning the option exists but does nothing. NixOS would still type-check and partially evaluate it. New: if a feature is not in the host's import list, it does not exist at all — no evaluation, no footgun.

**3. The host file is the single source of truth for what a machine runs.**
Old: to understand what runs on kt480, you had to read `configuration.nix` (which imported everything) and search for `enable = false` overrides scattered across it. New: read `kt480.nix` once — the import lists are the complete picture.

**4. Adding a second host is trivial.**
Old: would require a new `configuration.nix` that imports the same `default.nix` with different `enable` overrides — implicit, error-prone. New: create `modules/hosts/desktop.nix`, pick a different subset of modules from `config.nixos` and `config.homeManager`. The individual module files are not touched.

**5. Modules cannot conflict through the aggregator.**
Old: all options funnelled through `default.nix`, so a typo or duplicate there broke the entire config. New: each module is independent; a broken module only breaks itself.
