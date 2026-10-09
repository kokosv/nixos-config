# NUT setup on Proxmox baremetal (Debian)

UPS model: **EG-UPS-033** (USB HID UPS)
USB plugged directly into the Proxmox host — no VM passthrough.

## BIOS: required pre-requisite

Set **AC Power Loss** (or "Restore on AC Loss" / "Power Restore Policy") to **"Last State"**
in BIOS — NOT "Always On".

- "Last State": if machine was running when AC failed → auto-boots when AC returns.
  If machine was manually shut down → stays off. Prevents booting on UPS battery alone.
- "Always On": boots any time DC power is present, including UPS battery — DANGEROUS.

With "Last State" + NUT ONBATT shutdown, the full cycle is automatic and safe:
power fails → NUT shuts down gracefully → power returns → BIOS boots → Proxmox starts VMs.

## Proxmox: VM auto-start

For each VM that should come back up after a power outage:
Proxmox GUI → VM → Options → **Start at boot = Yes**

`pve-guests.service` handles graceful VM shutdown automatically when the host shuts down
(ACPI shutdown to each VM, waits for clean stop). No custom scripting needed.

---

## Install

```bash
apt install nut
```

## /etc/nut/nut.conf

```
MODE=netserver
```

## /etc/nut/ups.conf

```
[ups]
  driver = usbhid-ups
  port = auto
  desc = "EG-UPS-033"
```

## /etc/nut/upsd.conf

Listen on the VM bridge IP so PeaNUT on the home VM can reach it.
Replace `10.0.0.1` with the actual Proxmox bridge IP (`ip addr show vmbr0`).
Firewall: allow 3493 TCP only from the bridge subnet.

```
LISTEN 127.0.0.1 3493
LISTEN 10.0.0.1 3493
```

```bash
# iptables — restrict NUT port to bridge subnet only
iptables -A INPUT -p tcp --dport 3493 -s 10.0.0.0/24 -j ACCEPT
iptables -A INPUT -p tcp --dport 3493 -j DROP
```

## /etc/nut/upsd.users

```
[monitor]
  password = <monitor-password>
  upsmon slave

[admin]
  password = <admin-password>
  upsmon master
  actions = set fsd
  instcmds = all
```

## /etc/nut/upsmon.conf

Shutdown is triggered via `upssched` with a 60-second delay (handles brief power blips
without causing unnecessary shutdown/reboot cycles — leaves ~9 min of battery for shutdown).

```
MONITOR ups@localhost 1 admin <admin-password> master

MINSUPPLIES 1
SHUTDOWNCMD "/sbin/shutdown -h now"
NOTIFYCMD /usr/sbin/upssched
POLLFREQ 5
POLLFREQALERT 5
HOSTSYNC 15
DEADTIME 15

NOTIFYMSG ONLINE  "UPS %s on line power"
NOTIFYMSG ONBATT  "UPS %s on battery"
NOTIFYMSG LOWBATT "UPS %s battery is low"
NOTIFYMSG SHUTDOWN "Auto shutdown proceeding"

NOTIFYFLAG ONLINE  SYSLOG+WALL+EXEC
NOTIFYFLAG ONBATT  SYSLOG+WALL+EXEC
NOTIFYFLAG LOWBATT SYSLOG+WALL+EXEC
NOTIFYFLAG SHUTDOWN SYSLOG+WALL+EXEC
```

## /etc/nut/upssched.conf

60-second timer: if still on battery after 60s, trigger shutdown.
If power returns before 60s, cancel the timer — no shutdown.

```
CMDSCRIPT /etc/nut/upssched-cmd
PIPEFN /var/run/nut/upssched.pipe
LOCKFN /var/run/nut/upssched.lock

AT ONBATT  * START-TIMER onbatt 60
AT ONLINE  * CANCEL-TIMER onbatt
AT LOWBATT * EXECUTE lowbatt
```

## /etc/nut/upssched-cmd

See `notes/ups/shutdown.sh` — copy or symlink to `/etc/nut/upssched-cmd` and `chmod +x`.

---

## Enable and start

```bash
chmod +x /etc/nut/upssched-cmd
systemctl enable nut-server nut-monitor
systemctl start  nut-server nut-monitor

# Verify UPS is detected
upsc ups@localhost
```

---

## Shutdown flow (full sequence)

1. AC power fails → UPS switches to battery
2. NUT detects ONBATT → `upssched` starts 60-second timer
3. If AC restored within 60s → timer cancelled → no shutdown
4. After 60s on battery → `upssched-cmd onbatt` → `shutdown -h now`
5. systemd initiates shutdown → `pve-guests.service` sends ACPI shutdown to all VMs
6. VMs shut down cleanly (filesystems properly unmounted)
7. Proxmox host powers off
8. UPS battery continues (only UPS circuitry drawing power — very slow drain)
9. AC returns → UPS restores output → BIOS "Last State" = was running → auto-boots
10. Proxmox boots → VMs with "Start at boot = Yes" auto-start

## PeaNUT connection (home VM)

PeaNUT OCI container on the home VM uses `NUT_HOST = <proxmox-bridge-ip>` (e.g. `10.0.0.1`)
and `NUT_PORT = 3493` with the `monitor` user credentials.
See `modules/home-vm/peanut.nix` (to be created in Stage 6).
