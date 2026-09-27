# Secret management via age encryption — https://github.com/ryantm/agenix
#
# HOW IT WORKS:
#   Secrets are .age files encrypted with one or more SSH/age public keys and
#   committed to the repo. At boot, NixOS decrypts them with the host's SSH
#   host private key and places them in /run/agenix/ (tmpfs — never on disk
#   between reboots). You reference /run/agenix/<name> in your config.
#
# WORKFLOW:
#   1. Get the host's SSH host public key:
#        cat /etc/ssh/ssh_host_ed25519_key.pub
#   2. Paste it into secrets/secrets.nix under the right host variable.
#   3. Create/edit a secret (runs $EDITOR with plaintext, saves encrypted):
#        cd ~/.nixos-config
#        nix run github:ryantm/agenix -- -e secrets/my-secret.age
#   4. Declare it in age.secrets in hosts/kt480.nix (see there for examples).
#   5. nixreb — the decrypted value is at /run/agenix/my-secret at runtime.
#   6. Re-encrypt ALL secrets after adding a new public key:
#        nix run github:ryantm/agenix -- -r
#
# SOPS-NIX ALTERNATIVE (https://github.com/Mic92/sops-nix):
#   Same concept but SOPS is the backend. Key differences:
#   - Secrets can be YAML/JSON/env, making diffs human-readable.
#   - Supports multiple backends: age, GPG, AWS KMS, GCP KMS, Azure Key Vault.
#   - Better for team workflows where multiple people need to edit secrets.
#   - More setup: need a .sops.yaml key config, sops CLI tool installed.
#   For a single-host personal config, agenix is the simpler choice.
#   To switch later: add inputs.sops-nix, import sops-nix.nixosModules.sops,
#   and replace age.secrets.* with sops.secrets.*.
{ lib, ... }: {
  options.nixos.agenix = lib.mkOption { type = lib.types.deferredModule; };

  config.nixos.agenix = { inputs, ... }: {
    imports = [ inputs.agenix.nixosModules.default ];
    # age.secrets are declared per-host in hosts/<host>.nix
  };
}
