# Proxmox / Baremetal Setup (monolit)

> Everything here runs on **monolit**, the physical Proxmox VE host (Debian) — configured
> manually via the Proxmox GUI and `apt`, **not reproducible through Nix**. This doc exists
> so that setup isn't lost. For the NixOS-managed side (VPS, homeserver VM), see
> `notes/homelab-architecture.md`.

---

## Checklist

- [x] Tailscale on monolit, joined to tailnet (`100.64.0.4`)
- [x] SSH on monolit — tailnet + LAN, key-only
- [x] `homeserver` VM provisioned (hardware config)
- [x] VM start-at-boot + BIOS power-loss settings
- [x] ZFS pool `kashon01` reorganized into 8 purpose-specific datasets
- [x] Proxmox Backup storage (`d01-vm-backup`)
- [x] Directory Mappings (7 datasets → home VM)
- [x] VirtioFS shares on home VM Hardware tab
- [x] sanoid installed, configured, confirmed working (replaces default `zfs-auto-snapshot`)
- [x] Old `zfs-auto-snap_*` snapshots cleaned up
- [ ] NUT / UPS — **abandoned**, this UPS isn't compatible with NUT; not pursuing
- [ ] Daily cron to copy `/etc/pve` + `/etc/nut` configs to `d05-dokumenti` — not set up
      (the `/etc/nut` half is moot now NUT's abandoned; `/etc/pve` backup still worth doing)
- [ ] Drive health monitoring (`smartd` self-tests, later Scrutiny + ntfy/Homarr) — planned,
      not set up
- [ ] Full ntfy setup as central notification hub (disk health/Scrutiny, Gatus, Jellyfin,
      Homarr) — see `notes/homelab-architecture.md` §13 — planned, not set up

---

## Host overview

- Host: `monolit`, Debian + Proxmox VE
- Tailscale: `100.64.0.4` (apt-installed, joined to the self-hosted Headscale tailnet)
- LAN: `192.168.100.100`
- SSH: listens on both the tailnet IP and the LAN IP; key-only, `PermitRootLogin prohibit-password`
- Networking: `vmbr0` — Proxmox's default Linux bridge. VMs attach to this for LAN
  connectivity (`192.168.100.0/24`, gateway `192.168.100.1`) — the `homeserver` VM's
  `ens18` interface is bridged through it.

### Physical drives

- `nvme0n1`, `nvme1n1` — boot disk + `fastvm` (LVM-thin, VM disks)
- `sda` (Seagate IronWolf), `sdb` (WD Gold) — the `kashon01` ZFS mirror, 14TB each

> Seagate's SMART raw values for `Raw_Read_Error_Rate`/`Seek_Error_Rate` are huge by
> design — vendor-specific packed encoding (e.g. seek-error count + total-seek count
> packed into one field), not literal error counts. WD reports these as plain counts
> instead, hence `sdb` showing `0`. Judge health by **Normalized vs Threshold**, not the
> raw number — both drives pass comfortably (`Failing: -` on every attribute, overall
> `PASSED`). Wearout `N/A` on both is also expected — it's an SSD/NVMe-only metric.

**Health monitoring — planned, not yet set up**:
- `smartmontools`/`smartd` on monolit (manual, Debian, apt install — outside the flake):
  weekly short + monthly long self-test. Negligible wear impact — self-tests are
  read-only, and polling SMART attributes is just reading firmware counters, not real
  disk activity.
- Later, for a dashboard + advance notifications: **Scrutiny** — split architecture,
  collector (needs `smartctl` + physical disk access) runs on monolit, dashboard +
  InfluxDB can run on homeserver (NixOS, in the flake), collector points at it via
  `COLLECTOR_API_ENDPOINT` over the tailnet. Alerts go out via ntfy — see "Future idea —
  ntfy as a central notification hub" in `notes/homelab-architecture.md` §13.

---

## Tailscale (apt)

NixOS modules don't apply here — installed via the official Tailscale apt repo (not in
Debian's default repos):

```bash
apt install tailscale
tailscale up --login-server https://headscale.vafla.eu
# then on the VPS: headscale nodes register --user koko --key <key>
```

Proxmox GUI reachable at `https://proxmox.vafla.eu` (tier 1, tailnet-only — see main doc §11).

---

## VM settings

- Each VM: **Options → Start at boot = Yes**
- BIOS: **AC Power Loss → Last State**

### `homeserver` VM hardware

- Machine type `q35`, BIOS `OVMF/UEFI` (Secure Boot **pre-enroll keys off** — NixOS ISO's
  bootloader isn't signed)
- 10 cores, CPU type `host` (passthrough)
- 26–30GB RAM
- 256GB disk on `fastvm` — a dedicated LVM-thin pool on a second SSD (`nvme1n1`), isolated
  from both the boot disk and the `kashon01` ZFS pool

---

## UPS + NUT

```
EG-UPS-033 (USB — direct to monolit, no passthrough)
      │
Proxmox baremetal (Debian)
  ├── NUT server (apt) — reads UPS via USB; SHUTDOWNCMD="shutdown -h now"
  │     └── Proxmox pve-guests.service gracefully stops all VMs on host shutdown
  └── home VM (NixOS)
```

NUT must live on the baremetal, not in a VM — the shutdown path has to be direct. When
the UPS hits critical battery, `upsmon` runs `shutdown -h now` on the host, and Proxmox's
`pve-guests.service` gracefully stops all VMs before the host powers off. Putting NUT in
a VM creates a race: Proxmox might kill the VM before it finishes signalling the host.

Install: `apt install nut`; deploy configs from `notes/ups/setup.md`:
```bash
cp notes/ups/{nut.conf,ups.conf,upsd.conf,upsd.users,upsmon.conf,upssched.conf} /etc/nut/
cp notes/ups/shutdown.sh /etc/nut/upssched-cmd
chmod +x /etc/nut/upssched-cmd
systemctl enable --now nut-server nut-monitor
upsc ups@localhost   # verify
```

**Status: abandoned — this UPS isn't compatible with NUT.** Not pursuing further; config
and steps kept here for reference in case of a hardware change later.

---

## ZFS pool + datasets (`kashon01`, RAID-1 mirror)

Originally 4 generic datasets, reorganized into 8 purpose-specific ones (all empty at
the time — no data migration needed):

```bash
zfs rename kashon01/d03-vm-backup kashon01/d01-vm-backup
zfs rename kashon01/d04-mc kashon01/d02-minecraft
zfs destroy -r kashon01/d01-archiv   # was empty, replaced by d06-knigi
zfs destroy -r kashon01/d02-lichni   # was empty, replaced by d05-dokumenti
zfs create kashon01/d03-tv
zfs create kashon01/d04-media
zfs create kashon01/d05-dokumenti
zfs create kashon01/d06-knigi
zfs create kashon01/d07-muzika
zfs create kashon01/d08-vid-archiv
```

| Dataset | Mounted in | Purpose |
|---|---|---|
| `kashon01/d01-vm-backup` | Proxmox backup storage (not a guest mount) | VM backups (`dump/`) — Proxmox manages retention, no sanoid |
| `kashon01/d02-minecraft` | home VM `/d02-minecraft` (VirtioFS) | Minecraft server data |
| `kashon01/d03-tv` | home VM `/d03-tv` (VirtioFS) | TV library |
| `kashon01/d04-media` | home VM `/d04-media` (VirtioFS) | General media |
| `kashon01/d05-dokumenti` | home VM `/d05-dokumenti` (VirtioFS) | Documents + `/etc/pve` → `pve/`, `/etc/nut` → `nut/` (host cron, not yet set up). Also receives CryptPad's data via a nightly rsync mirror (`cryptpad-backup.timer`) — CryptPad's live storage is `/var/lib/cryptpad` on the VM's root disk, **not** this dataset directly |
| `kashon01/d06-knigi` | home VM `/d06-knigi` (VirtioFS) | Calibre library — dataset root **is** the library root, no subfolder |
| `kashon01/d07-muzika` | home VM `/d07-muzika` (VirtioFS) | Music library |
| `kashon01/d08-vid-archiv` | home VM `/d08-vid-archiv` (VirtioFS) | Video archive |
| `kashon01/d09-kino` | home VM `/d09-kino` (VirtioFS) | Kino (movies) library |

`kashon01` itself was never registered as a Proxmox ZFS-type storage backend — VM disks
live on `fastvm` instead, not on `kashon01`. The pool is only ever consumed via the
VirtioFS shares below and the `d01-vm-backup` Directory storage.

### Proxmox Backup storage (`d01-vm-backup`)

Datacenter → Storage → Add → Directory → path `/kashon01/d01-vm-backup`, content: Backup.
Retention set in the storage's Edit → Prune options. **No sanoid snapshots on this
dataset** — ZFS snapshots on a backup-file dataset would silently hold deleted VZDump
files alive, consuming large amounts of space.

> Proxmox's storage path field isn't editable after creation — after `zfs rename
> kashon01/d03-vm-backup kashon01/d01-vm-backup`, had to delete and recreate the storage
> entry entirely rather than just editing the path.

**Full VM recreation from a backup alone**: a VZDump backup bundles both the disk(s) and
the VM's hardware config (CPU/RAM, NICs, VirtioFS device entries) — Restore recreates the
whole VM from just the backup file. Not included: the Directory Mappings themselves (host
-level resource, not part of the VM) — recreate them (same names, see below) on the target
host first, or the restored VM's VirtioFS devices won't have anything to attach to.

### Directory Mappings (Datacenter → Resource Mappings → Directory)

```
d02-minecraft   →  /kashon01/d02-minecraft
d03-tv          →  /kashon01/d03-tv
d04-media       →  /kashon01/d04-media
d05-dokumenti   →  /kashon01/d05-dokumenti
d06-knigi       →  /kashon01/d06-knigi
d07-muzika      →  /kashon01/d07-muzika
d08-vid-archiv  →  /kashon01/d08-vid-archiv
d09-kino        →  /kashon01/d09-kino
```
(`d01-vm-backup` has no mapping — it's backup storage only, never a guest mount.)

> These store a fixed host **path**, not a live reference to the ZFS dataset — `zfs
> rename` does **not** update them, the old mapping is just left pointing at a path that
> no longer exists. Had to delete and recreate `d02-minecraft`'s mapping after its rename.

### VirtioFS shares (home VM → Hardware → Add → VirtioFS)

One device per mapping above, tag matching the dataset name. The actual NixOS
`fileSystems` declarations consuming these tags live in
`hosts/homeserver/homeserver.nix` (that part *is* Nix-managed).

> **No hot-unplug.** Removing a device from the VM's Hardware tab only edits its config —
> the host-side `virtiofsd` process still holds the directory open (blocks `zfs destroy`
> with "dataset is busy") until the VM is actually rebooted.

---

## Snapshot management: sanoid

Replaced Proxmox's default `zfs-auto-snapshot` (same fixed retention pool-wide, installed
by Proxmox automatically) with sanoid for per-dataset control.

**Disable `zfs-auto-snapshot`** (package left installed, just not running — fully
reversible by moving these back):
```bash
mv /etc/cron.d/zfs-auto-snapshot /etc/cron.d/zfs-auto-snapshot.disabled
mv /etc/cron.hourly/zfs-auto-snapshot /etc/cron.hourly/zfs-auto-snapshot.disabled
mv /etc/cron.daily/zfs-auto-snapshot /etc/cron.daily/zfs-auto-snapshot.disabled
mv /etc/cron.weekly/zfs-auto-snapshot /etc/cron.weekly/zfs-auto-snapshot.disabled
mv /etc/cron.monthly/zfs-auto-snapshot /etc/cron.monthly/zfs-auto-snapshot.disabled
```

**Delete old `zfs-auto-snapshot`-tool snapshots** (different naming than sanoid's own —
`zfs-auto-snap_*` vs sanoid's `autosnap_*` — this only ever matches the old tool's, never
touches sanoid's):
```bash
zfs list -H -t snapshot -o name | grep '@zfs-auto-snap' | xargs -n1 zfs destroy
```

**Install sanoid:**
```bash
apt install sanoid
```

**`/etc/sanoid/sanoid.conf`** (deployed, confirmed working):
```ini
[kashon01/d02-minecraft]
  use_template = minecraft

[kashon01/d03-tv]
  use_template = archival

[kashon01/d04-media]
  use_template = personal

[kashon01/d05-dokumenti]
  use_template = documents

[kashon01/d06-knigi]
  use_template = archival

[kashon01/d07-muzika]
  use_template = archival

[kashon01/d08-vid-archiv]
  use_template = archival

[kashon01/d09-kino]
  use_template = archival

# d01-vm-backup: NO sanoid — Proxmox manages VZDump retention directly

[template_minecraft]
  hourly  = 24
  daily   = 7
  weekly  = 4
  monthly = 0
  yearly  = 0
  autosnap = yes
  autoprune = yes

[template_documents]
  hourly  = 0
  daily   = 7
  weekly  = 4
  monthly = 0
  yearly  = 0
  autosnap = yes
  autoprune = yes

[template_personal]
  hourly  = 0
  daily   = 7
  weekly  = 4
  monthly = 3
  yearly  = 0
  autosnap = yes
  autoprune = yes

[template_archival]
  hourly  = 0
  daily   = 0
  weekly  = 8
  monthly = 0
  yearly  = 0
  autosnap = yes
  autoprune = yes
```

> Every retention value must be set explicitly, including `0`s. An omitted key does
> **not** mean 0 — sanoid falls back to its own non-zero built-in default for it. Omitting
> `hourly` from a template caused unwanted hourly snapshots on every dataset until fixed.

**Enable:**
```bash
systemctl enable --now sanoid.timer
```

**Verify / force a run:**
```bash
sanoid --verbose --cron
zfs list -t snapshot | grep kashon01
```

### Using snapshots

**Browsing and recovering files works from either side** — VirtioFS passes `.zfs`
through transparently, so it's reachable both on the Proxmox host (`/kashon01/<dataset>`)
and inside the home VM (`/<dataset>`), no host-hopping required for a simple file
recovery. `.zfs` is hidden from directory *enumeration* by ZFS design though — `ls -a` on
the parent will never show it on either side; it still exists and works if referenced by
its exact path.

```
/<dataset>/.zfs/snapshot/<snapshot-name>/
```

```bash
# browse one directly — ls -a on the parent won't reveal .zfs, name it explicitly
# (works from either the home VM at /d06-knigi/... or the host at /kashon01/d06-knigi/...)
ls /d06-knigi/.zfs/snapshot/
ls /d06-knigi/.zfs/snapshot/autosnap_2026-10-16_daily/

# recover one file — copy it back out of the snapshot into the live dataset
cp /d06-knigi/.zfs/snapshot/autosnap_2026-10-16_daily/path/to/file.txt /d06-knigi/
```

**Actual ZFS pool administration (`zfs list`, `rollback`, `clone`) only works on the
Proxmox host** — the VM has no `zfs` tooling or pool access, just the shared directory
view via VirtioFS:

```bash
# list snapshots for a dataset (sorted oldest to newest) — host only
zfs list -t snapshot -o name,creation -s creation | grep d06-knigi

# roll back an entire dataset (destructive — all changes since the snapshot are lost)
zfs rollback kashon01/d06-knigi@autosnap_2026-10-16_daily

# clone a snapshot into a new writable dataset (non-destructive, for a full-tree restore
# without touching the live dataset)
zfs clone kashon01/d06-knigi@autosnap_2026-10-16_daily kashon01/d06-knigi-recovered
```

The `cp`-from-snapshot route is the one to reach for almost always; `zfs rollback` is only
for "I want the whole dataset back exactly as it was," since it discards everything
written after that snapshot.

---

## Troubleshooting

### VM won't boot after removing/renaming VirtioFS devices in Hardware

If the active NixOS generation on the VM still references VirtioFS mounts that were just
removed from Hardware, boot fails (drops to `emergency.target` — SSH never comes up since
`multi-user.target` is never reached). Recover from the Proxmox console:

```bash
# /nix/store is a SEPARATE read-only bind mount from / — remount it first,
# remounting / alone isn't enough
mount -o remount,rw /nix/store

systemctl --failed
# for each failed *.mount unit shown, quote it (shell eats the literal
# backslash in systemd's \x2d-escaped unit names otherwise):
systemctl mask '<unit>.mount'

systemctl daemon-reload
systemctl reset-failed
systemctl default
```

Then deploy the corrected NixOS config from kt480 (`nixos-rebuild switch --target-host`)
and reboot once more to clear the masks.

> The `mount -o remount,rw /nix/store` fix does **not** persist — after any reboot/VM
> restart, `/nix/store` goes back to read-only, and `systemctl mask`/`unmask` will fail
> again with "Read-only file system" until it's remounted rw again. Also: `systemctl
> unmask`/`start` on a `\x2d`-escaped unit name reliably gets mangled by shell quoting
> through SSH — more robust to resolve the exact name first (`systemctl list-units --all
> --type=mount | grep <name>`) and reference it via a script file on the remote host
> rather than inline shell escaping.

### Adding a VirtioFS share to an already-running VM

A new VirtioFS device added in the VM's Hardware tab does **not** attach on a guest
**Reboot** — Reboot restarts the OS inside the same already-running QEMU process, which
still has the old device list from when it was launched. The VM must be fully **Stopped**,
then **Started** (not Reboot) for a newly added VirtioFS device to actually appear
(confirmed via `dmesg | grep virtiofs` — the tag simply doesn't show up at all until this
is done, not a mount failure, an absent device).

---

## Summary

| Component | Where | How reached |
|---|---|---|
| Tailscale | Proxmox baremetal (apt) + each VM | tailnet |
| Proxmox web GUI | VPS nginx → Proxmox baremetal `:8006` | tailnet only (`proxmox.vafla.eu`) |
| SSH — Proxmox baremetal | Proxmox baremetal | tailnet (`100.64.0.4`) + local LAN IP |
| SSH — home VM | `homeserver` | tailnet (`100.64.0.5`) + static LAN (`192.168.100.56`) |
| UPS USB | Direct to Proxmox baremetal | local USB on host |
| NUT server | Proxmox baremetal (apt) | abandoned — UPS incompatible |
| Shutdown | baremetal NUT → `shutdown -h now` | `pve-guests.service` stops VMs first |
