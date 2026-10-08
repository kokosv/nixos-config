# agenix access control — defines which public keys can decrypt which secrets.
# This file is read by the agenix CLI, NOT imported by NixOS.
#
# TWO KINDS OF KEYS go here — do not confuse them:
#
#   HOST keys  — /etc/ssh/ssh_host_ed25519_key.pub on each machine.
#                Used by agenix to decrypt secrets AT BOOT (as root).
#                Get with: cat /etc/ssh/ssh_host_ed25519_key.pub
#
#   USER keys  — ~/.ssh/id_ed25519.pub (your personal key).
#                Optional. Lets you run `agenix -e` as yourself without
#                needing root, and from other machines.
#                Get with: cat ~/.ssh/id_ed25519.pub
#
# The CONTENT stored inside a .age file is unrelated to these recipients —
# the .age file can hold anything (e.g. your SSH private key, a password).
#
# After adding a new public key here, re-encrypt all affected secrets:
#   nix run github:ryantm/agenix -- -r
let
  # ── host keys (for boot decryption) ─────────────────────────────────────────
  kt480 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDGbip9p6/LouVHZbgAjnf4tB2FZmwtPvRwt7py7Zvcn root@kt480";
  vps = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA1WNxUkom4X0JT0pq+1/svnTkL6revNEDlDq/g3GELx root@nixos";
  # klegion = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI REPLACE_ME root@klegion";

  # ── user keys (optional, for editing secrets without root) ───────────────────
  koko = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINB4MjILO3RVWMZ7M4PF+tiWcnqSEoNdBMe21uTjUXxS koko@kt480";

  # ── recovery key — a standalone age identity, NOT tied to any machine.
  #    Private key lives only in the password manager, never on any host's
  #    disk. Exists so a lost/wiped machine can never fully lock us out again.
  recovery = "age1l30csms7ets0tp8n4c35kz4qkpp7kz23h8v8ejkjs3sspceafcds772l05";

  # ── groups ───────────────────────────────────────────────────────────────────
  allHosts = [
    kt480
    vps # klegion
  ];
  allKeys = allHosts ++ [ koko recovery ];
in
{
  # ── shared secrets ───────────────────────────────────────────────────────────
  # Encrypted for all hosts + koko so either can decrypt/edit.
  "secrets/ssh-private-key.age".publicKeys = allKeys;

  # ── vps secrets ──────────────────────────────────────────────────────────────
  "secrets/desec-token.age".publicKeys = [ vps koko recovery ];
  "secrets/headplane-cookie-secret.age".publicKeys = [ vps koko recovery ];

  # ── host-specific secrets (examples) ─────────────────────────────────────────
  # "secrets/kt480-wifi-password.age".publicKeys = [ kt480 koko ];
}
