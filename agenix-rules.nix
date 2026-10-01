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
  kt480 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGR+/0RcRTLMJJqQkkTXtgMxohS1BWLWmi94BP0tIf/K root@kt480";
  vps = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA1WNxUkom4X0JT0pq+1/svnTkL6revNEDlDq/g3GELx root@nixos";
  # klegion = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI REPLACE_ME root@klegion";

  # ── user keys (optional, for editing secrets without root) ───────────────────
  koko = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFKL/Ju54BCsGZfK5bCpeWl+Zfqu3RK6TfjcSUhKkQiY kaloyansv@gmail.com";

  # ── groups ───────────────────────────────────────────────────────────────────
  allHosts = [
    kt480
    vps # klegion
  ];
  allKeys = allHosts ++ [ koko ];
in
{
  # ── shared secrets ───────────────────────────────────────────────────────────
  # Encrypted for all hosts + koko so either can decrypt/edit.
  "secrets/ssh-private-key.age".publicKeys = allKeys;

  # ── vps secrets ──────────────────────────────────────────────────────────────
  "secrets/desec-token.age".publicKeys = [ vps koko ];
  "secrets/headplane-cookie-secret.age".publicKeys = [ vps koko ];

  # ── host-specific secrets (examples) ─────────────────────────────────────────
  # "secrets/kt480-wifi-password.age".publicKeys = [ kt480 koko ];
}
