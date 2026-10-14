# Homelab Architecture Reference

> Purpose of this file: a single source of truth describing the full self-hosted
> infrastructure — layout, request flow, and setup specifics — so a new chat/session (or a
> future version of me) can pick up context immediately without re-deriving it from scratch.
>
> Note: this doc intentionally covers **infrastructure only** (proxy, TLS, tailnet,
> firewall, bot protection, brute-force protection) — not specific applications.

---

## 1. High-level goal

Self-host a stack of services from a **home server**, made publicly reachable through a
**VPS**, with:

- A single domain (`vafla.eu`) with wildcard TLS via Let's Encrypt (DNS-01, deSEC), with DNSSEC.
- A **self-hosted** Tailscale control plane (Headscale) connecting home ↔ VPS, no
  third-party coordination server dependency — including a **self-hosted DERP relay**
  co-located on the VPS.
- **Anubis** (anti-scraper/bot proof-of-work challenge) in front of all public HTTP services
  except `headscale.vafla.eu` (Tailscale API clients fail PoW challenges). Tailnet-only
  services are exempt — they're unreachable from the internet.
- **No central SSO layer.** Each service uses its own login, if it has one. **fail2ban runs
  on the VPS** watching nginx access logs for per-service failed-login patterns, banning
  real attacker IPs at the VPS firewall before they reach the tailnet. (Running fail2ban on
  the home VM would be useless: all traffic arrives from the VPS tailscale IP, so banning
  there would block the VPS itself, not the attacker.) A central SSO layer (Authentik) was
  built and then removed — see §14 for why.
- Everything declared in **Nix** (NixOS), on a VM hosted under **Proxmox** at home.

---

## 2. Physical / infra layout

```
┌─────────────────────────────────────────────────────────────┐
│  Home: Proxmox host "monolit" (Debian)                       │
│    ├── Tailscale (apt) — 100.64.0.4, tailnet SSH + LAN SSH   │
│    │     fallback (192.168.100.100)                          │
│    ├── NUT server (apt) — reads EG-UPS-033 USB directly      │
│    └── NixOS VM "homeserver" — 100.64.0.5 (tailnet) /        │
│          192.168.100.56 (static LAN)                          │
│          - 10 cores (host passthrough), 26-30GB RAM,          │
│            256GB disk on `fastvm` (dedicated LVM-thin pool,   │
│            nvme1n1, isolated from boot disk + kashon01 RAID)  │
│          - Runs MC server too — no separate MC VM             │
│          - Technitium DNS — deployed, `vafla.eu` zone live    │
│          - Enclosed (secure note sharing) — deployed          │
│          - No public ports open. SSH reachable over tailnet   │
│            and LAN (not tailnet-only, unlike the original     │
│            plan — see §14)                                    │
└─────────────────────────────────────────────────────────────┘
                              │
                     Tailscale tunnel (WireGuard)
                     control plane = self-hosted Headscale
                     relay fallback = self-hosted DERP (on VPS)
                              │
┌─────────────────────────────────────────────────────────────┐
│  VPS (public IP, NixOS)                                      │
│    - nginx reverse proxy (public entry point)                │
│    - Headscale + DERP                                        │
│    - Anubis (public services), fail2ban, geoip blocking      │
│    - Gatus status page (bachkali.vafla.eu)                   │
└─────────────────────────────────────────────────────────────┘
```

---

## 3. DNS & TLS

- **Registrar:** ClouDNS (domain registration only)
- **DNS hosting:** deSEC.io (free, DNSSEC auto-signed, REST API for lego)
- **ACME:** Let's Encrypt DNS-01 via lego (`dnsProvider = "desec"`)
- **Cert:** `*.vafla.eu` + `vafla.eu` + `map.mc.vafla.eu` — one wildcard covers all subdomains
- **DNSSEC:** deSEC auto-signs; DS record (SHA-256) added at ClouDNS registrar

During NS migration or stale-cache periods, temporarily use `1.1.1.1` to avoid stale NS.
Verify DNSSEC with: `dig +dnssec vafla.eu @86.54.11.100` — look for `ad` flag.

---

## 4. Tailscale / Headscale / DERP

- **Headscale** runs on the VPS (stable public address, always up)
- **DERP relay** co-located on VPS, region_id 999, STUN on :3478
- `derp.urls = []` — disables fallback to Tailscale's public DERP servers
- All nodes join via: `tailscale up --login-server https://headscale.vafla.eu`

```nix
services.headscale = {
  enable = true;
  address = "0.0.0.0";
  port = 8080;
  settings = {
    server_url = "https://headscale.vafla.eu";
    dns = {
      base_domain = "tailnet.vafla.eu";
      nameservers.global = [ "86.54.11.100" ]; # DNS4EU — catch-all
      nameservers.split."vafla.eu" = [ "100.64.0.5" ]; # Technitium — authoritative for vafla.eu
    };
    derp.server = {
      enabled = true; region_id = 999;
      region_code = "home"; region_name = "Home";
      stun_listen_addr = "0.0.0.0:3478";
    };
    derp.urls = [];
  };
};
```

> `headscale.vafla.eu` must resolve to the VPS's **real public IP** everywhere, including
> from tailnet clients — never the tailscale IP. DERP/STUN bootstrap needs a real
> internet path; pointing it at `100.64.x.x` is a chicken-and-egg deadlock.

---

## 5. Geo-blocking

Country-level IP blocking on all **public-tier** nginx virtualHosts. Headscale exempt.

**Database:** db-ip.com free MMDB (no registration). Downloaded monthly via systemd timer
to `/var/lib/geoip/dbip-country-lite.mmdb`. `auto_reload 1d` hot-reloads without restart.

**Blocked:** US, CN, RU, UA, BY, GB, IL.

```nginx
geoip2 /var/lib/geoip/dbip-country-lite.mmdb {
  auto_reload 1d;
  $geoip2_country_code default=XX country iso_code;
}
map $geoip2_country_code $geo_blocked {
  default 0;
  US 1; CN 1; RU 1; UA 1; BY 1; GB 1; IL 1;
}
```

Add to each public tier-0b virtualHost location:
```nix
extraConfig = ''if ($geo_blocked) { return 403; }'';
```

---

## 6. Firewall

NixOS native `networking.firewall` (nftables-backed).

**VPS:**
```nix
networking.firewall = {
  enable = true;
  allowedTCPPorts = [ 22 80 443 25565 ];
  allowedUDPPorts = [ 3478 25565 ];
  trustedInterfaces = [ "tailscale0" ];
  checkReversePath = "loose";
};
services.tailscale.enable = true;
```

**Home VM ("homeserver"):** no public ports. SSH listens on both `100.64.0.5` (tailnet)
and `192.168.100.56` (static LAN, gateway `192.168.100.1`) — deliberately not tailnet-only
like originally planned; see §14 for why. `networking.useDHCP = false`, static address set
declaratively so `sshd`'s `listenAddresses` stays valid across reboots.

---

## 7. fail2ban

Runs on the **VPS**, watching nginx + sshd. Correct location because all public traffic
enters the VPS — real attacker IPs are only visible there.

```nix
services.fail2ban = {
  enable = true; maxretry = 5; bantime = "1h";
  bantime-increment.enable = true;
  ignoreIP = [ "100.64.0.0/10" ]; # never ban the tailnet — trusted at the firewall anyway
  jails = {
    sshd.settings = { enabled = true; port = "22"; filter = "sshd"; maxretry = 4; };
    nginx-http-auth.settings = { enabled = true; filter = "nginx-http-auth"; logpath = "/var/log/nginx/error.log"; backend = "polling"; };
    nginx-botsearch.settings = { enabled = true; filter = "nginx-botsearch"; logpath = "/var/log/nginx/access.log"; backend = "polling"; };
    nginx-enclosed = {
      settings = { enabled = true; logpath = "/var/log/nginx/access.log"; backend = "polling"; maxretry = 5; };
      filter.Definition.failregex = ''^<HOST> .*"POST /api/auth/login HTTP/\d\.\d" 401'';
    };
  };
};
```

**`backend = "polling"` is required on every nginx-based jail.** NixOS's fail2ban
defaults to the systemd-journal backend, which only sees what a service prints to its
own stdout/stderr — nginx logs to files (`access.log`/`error.log`) instead, so the
journal backend silently never matches anything. This affected `nginx-http-auth` and
`nginx-botsearch` from the start (both sat at 0 total failed despite real bot traffic)
until caught during `nginx-enclosed`'s first live test. `sshd` is unaffected — NixOS's
openssh genuinely logs via journald, so the default backend is correct there.

**Per-app custom jails** — for any public service with its own login (none of them sit
behind a central SSO — see §14), add a jail watching `access.log` for that app's specific
`<login path> → <failure status>` signature, same pattern as `nginx-enclosed` above.
Works because nginx logs every proxied response's status regardless of backend — no
need for fail2ban to see anything on homeserver itself. Confirm the exact path/status
from a real failed login attempt before writing the regex, don't guess it.

**Self-banning during testing**: repeated manual login testing (e.g. retrying a wrong
password several times while debugging) looks identical to a brute-force attempt and
will legitimately trip these jails — that's the system working correctly, not a bug.
`ignoreIP` only exempts the tailnet; testing from a public IP is still subject to the
same rules as anyone else. Use `fail2ban-client unban --all` to recover if self-banned.

---

## 8. Anubis — public services only

`services.anubis` is a native NixOS module. One instance per public service, each with
its own Unix socket. All instances and their nginx virtualHosts live in `modules/vps/anubis.nix`.

Socket path format: `BIND = "/run/anubis/anubis-<name>/anubis.sock"` (no `unix:` prefix in BIND;
nginx proxyPass uses `http://unix:/run/anubis/anubis-<name>/anubis.sock`).

nginx must be in the `anubis` group: `users.users.nginx.extraGroups = [ "anubis" ];`

**Difficulty**: the global `DIFFICULTY` setting is just a fallback — Anubis's built-in
weight-threshold tiers (`useDefaultBotRules`) hardcode their own per-tier difficulty and
override it. Normal browsers land in the "moderate-suspicion" tier, which defaults to
difficulty 2 regardless of `DIFFICULTY`. Overridden globally via
`services.anubis.defaultOptions.policy.settings.thresholds` in `modules/vps/anubis.nix`
to bump that tier to 4. Not a hard cap either way — Anubis's own default goes to 6 for
its highest tier.

**Exemptions:**
- `headscale.vafla.eu` — Tailscale API clients can't complete PoW challenges
- All tailnet-only (tier 1) services — unreachable from public internet

**Request chains by tier:**
```
# Tier 0a — headscale (bare)
nginx (TLS) → headscale

# Tier 0b — public (Anubis only)
nginx (TLS) → Anubis → backend

# Tier 1 — tailnet-only (no Anubis, no SSO — just the app's own login, if any)
nginx (TLS, tailscale0) → backend
```

---

## 9. Secrets management — agenix

`agenix` (ryantm/agenix) encrypts secrets per-host using SSH public keys.
Each secret is re-encrypted for every host that needs it.

- Rules file: `agenix-rules.nix` — maps secret files to allowed host/user keys
- Secrets directory: `secrets/` — `.age` files committed to git (safe, encrypted)
- In NixOS modules: `age.secrets.<name>.file = ../../secrets/<name>.age;`
- Secret path at runtime: `config.age.secrets.<name>.path`

Current secrets:
- `secrets/desec-token.age` — deSEC API token for ACME DNS-01
- `secrets/headplane-cookie-secret.age` — Headplane session signing key
- `secrets/ssh-private-key.age` — kt480 SSH private key
- `secrets/enclosed-env.age` — `AUTHENTICATION_JWT_SECRET=...` +
  `AUTHENTICATION_USERS=...` (homeserver)

`homeserver` is a registered agenix host (in `allHosts` in `agenix-rules.nix`).

---

## 10. Tailnet DNS — Technitium + DNS4EU fallback

Technitium runs on the home VM (`homeserver`, `100.64.0.5`) via `services.technitium-dns-server`
(`modules/homeserver/technitium.nix`). `openFirewall = false` — `tailscale0` is already trusted.

Headscale split-DNS (`modules/vps/headscale.nix`): `nameservers.split."vafla.eu" = [
"100.64.0.5" ]`, `nameservers.global = [ "86.54.11.100" ]`. Every tailnet device sends
`vafla.eu` queries to Technitium, everything else to DNS4EU.

**Zone structure in Technitium** — `vafla.eu` itself is a **Forwarder** zone (→
`86.54.11.100`), not Primary. Tailnet-specific overrides live in their own, more specific
**Primary** zones (most-specific-match wins):
- `dns.vafla.eu` → `100.64.0.1` (tier 1, no public record)
- `proxmox.vafla.eu` → `100.64.0.1` (tier 1, no public record)
- `headplane.vafla.eu` → `100.64.0.1` (tier 1, no public record)
- `headscale.vafla.eu` → `31.70.105.226` (VPS **public** IP — needed for DERP bootstrap,
  see §4; this is the one record that must NOT point at the tailscale IP)

Everything else (public tier 0a/0b subdomains) needs no entry — the Forwarder zone
handles it automatically. Only add a new zone here when a subdomain has no public DNS
record at all.

Local machine DNS (non-tailnet): `86.54.11.100 86.54.11.200` (joindns4.eu — DNSSEC validating).

---

## 11. Service access tiers and service map

Three tiers. The distinction is made in DNS and nginx config.
TLS works for all — the cert covers `*.vafla.eu` + `vafla.eu` + `map.mc.vafla.eu`.

### Tier 0a — public, bare (headscale only)

| Subdomain | Service | Why exempt |
|---|---|---|
| `headscale.vafla.eu` | Headscale control plane | Tailscale API clients can't complete PoW |

### Tier 0b — public, Anubis only

deSEC A record → VPS public IP. No central SSO — any login-gated service here uses its
own login, protected by fail2ban (§7).

| Subdomain | Service | Backend |
|---|---|---|
| `vafla.eu` | MC server :25565 (TCP) + Matrix homeserver (tuwunel, `/_matrix` path, needs LiveKit for calls) + future landing page | VPS (mc-proxy) / home VM |
| `mc.vafla.eu` | Static page (server info, modpack, voice chat, map link) | home VM |
| `map.mc.vafla.eu` | Bluemap (MC world map) | home VM |
| `bachkali.vafla.eu` | Gatus (status page) | VPS localhost:8081 |
| `rechnik.vafla.eu` | TBD | home VM |
| `taina.vafla.eu` | Enclosed (secure note sharing) — **deployed**, own account-gated creation | home VM (`100.64.0.5:8787`) |
| `git.vafla.eu` | Forgejo | home VM |
| `nazhivo.vafla.eu` | Owncast | home VM |
| `dok.vafla.eu` | Cryptpad — registration closed after creating one admin account; single-user usage, sharing documents via direct link only, not open to other registered users | home VM |
| `tube.vafla.eu` | Peertube | home VM |
| `tv.vafla.eu` | Jellyfin | home VM |
| `media.vafla.eu` | Immich | home VM |

### Tier 1 — tailnet-only (no Anubis, no SSO)

No deSEC record. Technitium resolves to VPS tailscale IP. nginx listens on `tailscale0`
only. Any login-gated service here uses its own login — tailnet-only reachability is the
access control.

| Subdomain | Service | Backend |
|---|---|---|
| `homarr.vafla.eu` | Homarr (dashboard) | home VM |
| `knigi.vafla.eu` | Calibre | home VM |
| `muzika.vafla.eu` | Navidrome (server) — clients: Feishin (desktop, native app, not hosted), Wavio (Android, Subsonic API) | home VM |
| `*arr.vafla.eu` | \*arr stack (TBD) | home VM |
| `dns.vafla.eu` | Technitium web UI — **deployed** | home VM (`100.64.0.5:5380`) |
| `headplane.vafla.eu` | Headplane (Headscale web UI) — **deployed** | VPS localhost:3000 |
| `proxmox.vafla.eu` | Proxmox web GUI — **deployed** | Proxmox baremetal (`100.64.0.4:8006`) |

### DNS summary

| Tier | deSEC record | Technitium record | nginx listens on | Anubis |
|---|---|---|---|---|
| 0a — headscale | `A` → VPS public IP | `A` → VPS **public** IP (DERP bootstrap, §4) | public | no |
| 0b — public | `A` → VPS public IP | none (Forwarder zone handles it, §10) | public | yes |
| 1 — tailnet | none | `A` → VPS tailscale IP | `tailscale0` only | no |

### nginx virtualHost patterns

```nix
# Tier 0b — public, Anubis only
services.nginx.virtualHosts."<service>.vafla.eu" = {
  forceSSL = true; useACMEHost = "vafla.eu";
  locations."/" = {
    proxyPass = "http://unix:/run/anubis/anubis-<service>/anubis.sock";
    extraConfig = ''if ($geo_blocked) { return 403; }'';
  };
};

# Tier 0a — headscale (bare)
services.nginx.virtualHosts."headscale.vafla.eu" = {
  forceSSL = true; useACMEHost = "vafla.eu";
  locations."/" = { proxyPass = "http://127.0.0.1:8080"; proxyWebsockets = true; };
};

# Tier 1 — tailnet-only
services.nginx.virtualHosts."<service>.vafla.eu" = {
  listenAddresses = [ "100.64.0.1" ];
  forceSSL = true; useACMEHost = "vafla.eu";
  locations."/" = { proxyPass = "http://100.64.0.5:<port>"; proxyWebsockets = true; };
};
```

---

### Implementation order

One at a time, each built end-to-end (app + nginx vhost + Anubis + DNS record, per its
own tier below) and tested before moving to the next:

1. `headplane.vafla.eu` — tier 1 ✓ deployed
2. `taina.vafla.eu` (Enclosed) — tier 0b ✓ deployed
3. `dok.vafla.eu` (Cryptpad) — tier 0b
4. `nazhivo.vafla.eu` (Owncast) — tier 0b
5. `knigi.vafla.eu` (Calibre) — tier 1
6. `homarr.vafla.eu` (Homarr) — tier 1
7. MC server + `map.mc.vafla.eu` (Bluemap, tier 0b) + `mc.vafla.eu` (static info page, tier 0b)
8. `rechnik.vafla.eu` — tier 0b
9. `git.vafla.eu` (Forgejo) — tier 0b
10. `vafla.eu` `/_matrix` (Matrix) — tier 0b, needs LiveKit deployed alongside for calls
11. `*arr.vafla.eu` stack (tier 1) + `tv.vafla.eu` (Jellyfin, tier 0b) — needs planning first
12. `tube.vafla.eu` (Peertube) — tier 0b
13. `media.vafla.eu` (Immich) — tier 0b
14. `muzika.vafla.eu` (Navidrome) — tier 1

---

## 12. VPS setup plan

### Domain / service list

**deSEC A records** (all → VPS public IP):

| Record | Tier | Service | When |
|---|---|---|---|
| `vafla.eu` | 0b | MC server :25565 (TCP) + Matrix `/_matrix` + future landing page | Stage 1 |
| `headscale.vafla.eu` | 0a | Headscale control plane | Stage 1 ✓ |
| `bachkali.vafla.eu` | 0b | Gatus | Stage 1 ✓ |
| `mc.vafla.eu` | 0b | Static page | Stage 5 |
| `map.mc.vafla.eu` | 0b | Bluemap | Stage 5 |
| `rechnik.vafla.eu` | 0b | TBD | Stage 5 |
| `taina.vafla.eu` | 0b | Enclosed | Stage 5 ✓ |
| `git.vafla.eu` | 0b | Forgejo | Stage 5 |
| `nazhivo.vafla.eu` | 0b | Owncast | Stage 5 |
| `dok.vafla.eu` | 0b | Cryptpad | Stage 5 |
| `tube.vafla.eu` | 0b | Peertube | Stage 5 |
| `tv.vafla.eu` | 0b | Jellyfin | Stage 5 |
| `media.vafla.eu` | 0b | Immich | Stage 5 |

**Technitium records — nginx-proxied services** (all → VPS tailscale IP, Stage 5):

| Record | Tier | Service |
|---|---|---|
| `homarr.vafla.eu` | 1 | Homarr |
| `knigi.vafla.eu` | 1 | Calibre |
| `muzika.vafla.eu` | 1 | Navidrome |
| `*arr.vafla.eu` | 1 | \*arr stack (TBD) |
| `dns.vafla.eu` | 1 | Technitium web UI |
| `headplane.vafla.eu` | 1 | Headplane — VPS-local backend |
| `proxmox.vafla.eu` | 1 | Proxmox web GUI — tailnet only, no Anubis; nginx → Proxmox baremetal tailscale IP:8006 |

SSH to Proxmox baremetal and homeserver uses their tailscale IPs directly
(`100.64.0.4`, `100.64.0.5`) — no dedicated SSH subdomain needed.

---

### Stage 1 — repo prep ✓

- [x] Provision VPS with NixOS
- [x] Add VPS host key to `agenix-rules.nix`, re-encrypt secrets
- [x] Transfer DNS hosting from ClouDNS to deSEC.io
- [x] Create deSEC API token → `secrets/desec-token.age`
- [x] Add `headscale.vafla.eu` A record in deSEC → VPS public IP
- [x] Add `bachkali.vafla.eu` A record in deSEC → VPS public IP
- [x] Add DS record (SHA-256) at ClouDNS registrar to complete DNSSEC chain

### Stage 2 — NixOS modules ✓

- [x] `modules/vps/agenix.nix`
- [x] `modules/vps/networking.nix` — firewall + tailscale + DNS (86.54.11.100 joindns4.eu)
- [x] `modules/vps/headscale.nix` — Headscale + embedded DERP + nginx virtualHost
- [x] `modules/vps/acme.nix` — wildcard cert via deSEC DNS-01
- [x] `modules/vps/nginx.nix` — base nginx with geoip2 module override
- [x] `modules/vps/fail2ban.nix` — sshd + nginx jails
- [x] `modules/vps/geoip.nix` — db-ip.com MMDB, monthly timer
- [x] `modules/vps/gatus.nix` — Gatus status page on `bachkali.vafla.eu:8081`, grouped
      VPS / MC / Home Server. Cert expiration checked only on Headscale (shared wildcard
      cert, redundant elsewhere).
- [x] `modules/vps/anubis.nix` — Anubis in front of Gatus; nginx group fix; geo-blocking
- [x] `modules/vps/headplane.nix` — tailnet-only, `listenAddresses`
- [ ] `modules/vps/mc-proxy.nix` — TCP stream proxy for Minecraft :25565 → home VM; deferred to Stage 5

### Stage 3 — first deploy and verify ✓

- [x] Deploy to VPS
- [x] Confirm headscale, nginx, tailscaled, fail2ban, gatus, anubis running
- [x] Confirm wildcard cert issued
- [x] Create Headscale user: `headscale users create koko`
- [x] Join VPS to its own tailnet
- [x] Note VPS tailscale IP — `100.64.0.1`, used in tier-1 `listenAddresses` throughout

### Stage 4 — enroll devices (in progress)

- [x] Join kt480 laptop — enrolled in tailnet
      > joindns4.eu had stale NS cache after deSEC migration; temporarily used 1.1.1.1.
      > Cache expired — switched back to `86.54.11.100 86.54.11.200`. ✓
- [x] Join phone (Android, kthinkphone) — enrolled
      > Headscale 0.28 had Android crash bug; fixed by upgrading to 0.29.4 via flake input.
- [~] Join Windows machine — skipped for now
- [x] Join home VM (`homeserver`) once provisioned — `100.64.0.5`
- [x] Note home VM tailscale IP — applied to `headscale.nix` `nameservers.global` and all
      tier-1 `proxyPass` targets (`100.64.0.5`)

### Stage 5 — service layer (after home VM is up with Technitium)

- [x] Provision home VM on Proxmox (NixOS) — named `homeserver`, `hosts/homeserver/`.
      q35 + OVMF/UEFI (Secure Boot pre-enroll off), 10 cores (`host` type), 26-30GB RAM,
      256GB disk on `fastvm`. MC server runs as a service inside this VM, not a separate VM.
- [x] Configure SSH on home VM — tailnet (`100.64.0.5`) + static LAN (`192.168.100.56`),
      key-only, `PermitRootLogin = "prohibit-password"` (see §14)
- [x] Set up Technitium on home VM — `modules/homeserver/technitium.nix` (see §10)
- [x] Set up Enclosed on home VM — `modules/homeserver/enclosed.nix` (secure note sharing,
      `taina.vafla.eu`, tier 0b)
- [x] Fill in home VM tailscale IP in `headscale.nix` `nameservers.global` (`100.64.0.5`)
- [x] Fill in VPS tailscale IP in tier-1 nginx `listenAddresses` (`100.64.0.1`) — used by
      `dns.vafla.eu`, `proxmox.vafla.eu`, `headplane.vafla.eu`
- [ ] Fill in home VM tailscale IP in `mc-proxy.nix` (MC server runs on home VM); wire into vps.nix
- [~] Add Anubis instances per service (`modules/vps/anubis.nix`) — done for `taina.vafla.eu`
      (Enclosed) and `gatus`; rest still pending per-service
- [ ] Add nginx virtualHosts for remaining tier-0b services
- [x] Add nginx virtualHosts for tier-1 services — `dns.vafla.eu`
      (`modules/vps/technitium-proxy.nix`), `proxmox.vafla.eu`
      (`modules/vps/proxmox-proxy.nix`), `headplane.vafla.eu` done; rest pending
- [ ] Add deSEC A records for all remaining tier-0b subdomains → VPS public IP
- [~] Add Technitium DNS records for all tier-1 subdomains → VPS tailscale IP — `dns`,
      `proxmox`, `headplane` done; rest pending

### Stage 6 — Proxmox host + UPS + ZFS storage (after home VM is up)

#### Proxmox host basics

- [x] **BIOS**: AC Power Loss → **Last State**
- [x] Install Tailscale on Proxmox Debian host (`apt install tailscale` — needed the
      official Tailscale apt repo first, not in Debian's default repos);
      registered with Headscale — `100.64.0.4`
- [x] Add Technitium record: `proxmox.vafla.eu` → VPS tailscale IP (`100.64.0.1`)
- [x] Add nginx virtualHost for `proxmox.vafla.eu` on VPS — no central SSO (Proxmox has
      its own login), proxyWebsockets, proxyPass → `100.64.0.4:8006`,
      `proxy_ssl_verify off` (Proxmox serves its own self-signed cert)
- [x] Configure SSH on Proxmox baremetal: listens on tailnet IP (`100.64.0.4`) + local LAN IP
      (`192.168.100.100`); key-only, `PermitRootLogin = "prohibit-password"`
- [x] Set each VM: Options → **Start at boot = Yes**

#### UPS + NUT

- [~] Install NUT (`apt install nut`); deploy configs from `notes/ups/setup.md`:
      copy `/etc/nut/{nut.conf,ups.conf,upsd.conf,upsd.users,upsmon.conf,upssched.conf}`;
      copy `notes/ups/shutdown.sh` → `/etc/nut/upssched-cmd`; `chmod +x /etc/nut/upssched-cmd`;
      `systemctl enable --now nut-server nut-monitor`; verify with `upsc ups@localhost`
      — attempted, didn't work, left unresolved

#### ZFS datasets + storage

- [x] ~~Add `kashon01` pool as Proxmox storage backend~~ — **decided unnecessary**. VM
      disks live on `fastvm` (dedicated LVM-thin pool on `nvme1n1`, isolated from both the
      boot disk and `kashon01`), not on `kashon01` directly. `kashon01` is only ever
      consumed via the VirtioFS directory shares below and the `d03-vm-backup` Directory
      storage — neither needs the pool registered as a ZFS-type Proxmox storage backend.
- [x] Create the four datasets:
      ```
      zfs create kashon01/d01-archiv
      zfs create kashon01/d02-lichni
      zfs create kashon01/d03-vm-backup
      zfs create kashon01/d04-mc
      ```
- [x] Add `kashon01/d03-vm-backup` as Proxmox Backup storage (ID: `d03-vm-backup`):
      Datacenter → Storage → Add → Directory → path: `/kashon01/d03-vm-backup`, content: Backup;
      retention set in storage Edit → Prune options — **no sanoid on this dataset**
- [ ] Install sanoid (`apt install sanoid`); write `/etc/sanoid/sanoid.conf` (see §13 for full config);
      `systemctl enable --now sanoid.timer` — snapshots and pruning run automatically
- [ ] Set up daily cron to copy configs to `d01-archiv` (add to `crontab -e` on Proxmox host):
      ```
      0 3 * * * rsync -a /etc/pve/ /kashon01/d01-archiv/pve/
      0 3 * * * rsync -a /etc/nut/ /kashon01/d01-archiv/nut/
      ```
- [x] Create Directory Mappings (Datacenter → Resource Mappings → Directory):
      ```
      d01-archiv  →  /kashon01/d01-archiv
      d02-lichni  →  /kashon01/d02-lichni
      d04-mc      →  /kashon01/d04-mc
      ```
- [x] Add VirtioFS shares to **home VM** (VM → Hardware → Add → VirtioFS):
      ```
      mapping: d01-archiv,  tag: d01-archiv
      mapping: d02-lichni,  tag: d02-lichni
      mapping: d04-mc,      tag: d04-mc
      ```
- [x] Declare mounts in **home VM** NixOS config:
      ```nix
      fileSystems."/d01-archiv" = { device = "d01-archiv"; fsType = "virtiofs"; };
      fileSystems."/d02-lichni" = { device = "d02-lichni"; fsType = "virtiofs"; };
      fileSystems."/d04-mc"     = { device = "d04-mc";     fsType = "virtiofs"; };
      ```

---

## 13. Open items / not yet finalized

### Gotchas hit provisioning the `homeserver` VM (for next time)

- Secure Boot must be off (uncheck "Pre-Enroll keys" on the EFI disk) — NixOS ISO's
  bootloader isn't signed.
- `disko`'s ESP partition needs `type = "EF00";` explicitly for `systemd-boot` to install
  (`bootctl` checks the GPT partition type GUID). GRUB doesn't need this.
- Nix flakes only see git-tracked files — `git add` (staging is enough) before building.
- `disko --mode destroy,format,mount` wipes `/mnt` entirely — regenerate
  `hardware-configuration.nix` after any re-run.
- `nixos-rebuild switch --target-host` activating a network change (DHCP → static) can
  kill the SSH session mid-activation. Recovery: Proxmox console → `ip addr add`/
  `ip route add` manually, then retry.

### Proxmox host on tailnet + UPS plan

#### Layout

```
EG-UPS-033 (USB — direct, no passthrough)
      │
Proxmox baremetal (Debian)
  ├── Tailscale (apt) — tailnet member, for Proxmox GUI access
  ├── NUT server (apt) — reads UPS via USB; SHUTDOWNCMD="shutdown -h now"
  │     └── Proxmox pve-guests.service gracefully stops all VMs on host shutdown
  └── home VM (NixOS)
        └── Tailscale (tailnet member)
```

NUT lives on the baremetal because the shutdown path must be direct: when the UPS
hits critical battery, `upsmon` runs `shutdown -h now` on the host, and
`pve-guests.service` gracefully stops all VMs before the host powers off.
Putting NUT in a VM creates a race — Proxmox might kill the VM before it has
finished signalling the host to shut down.

#### Step 1 — Proxmox host on the tailnet

The Proxmox web GUI (port 8006) runs on the baremetal. Install Tailscale with `apt`
(NixOS modules don't work on Debian):

```bash
apt install tailscale
tailscale up --login-server https://headscale.vafla.eu
# then on VPS: headscale nodes register --user koko --key <key>
```

Technitium record: `proxmox.vafla.eu` → VPS tailscale IP — nginx proxies to Proxmox
baremetal `:8006`, no central SSO (`proxyWebsockets = true` required for the console).

Access GUI at `https://proxmox.vafla.eu` on the tailnet.

#### Step 2 — NUT on Proxmox baremetal (Debian, `apt`)

USB is plugged directly into the Proxmox host — no passthrough needed.
See `notes/ups/` for the exact `/etc/nut/` config files and the shutdown script.

Key points:
- `upsmon.conf`: `SHUTDOWNCMD "/sbin/shutdown -h now"`
- Proxmox's `pve-guests.service` fires during systemd shutdown and stops all VMs
  gracefully before the host powers off — no custom Proxmox API scripting needed

### ZFS datasets + sanoid snapshot plan

#### Datasets on `kashon01` (RAID-1 mirror)

| Dataset | Mounted in | Purpose |
|---|---|---|
| `kashon01/d01-archiv` | home VM `/d01-archiv` (VirtioFS) | Archival data + `/etc/pve` → `pve/`, `/etc/nut` → `nut/` (host cron) |
| `kashon01/d02-lichni` | home VM `/d02-lichni` (VirtioFS) | Personal files — subdir structure TBD |
| `kashon01/d03-vm-backup` | Proxmox backup storage | VM backups (`dump/`) — retention managed by Proxmox, no sanoid snapshots |
| `kashon01/d04-mc` | home VM `/d04-mc` (VirtioFS) | Minecraft server data — subdir structure TBD |

#### Sanoid snapshot retention (`/etc/sanoid/sanoid.conf` on Proxmox baremetal)

Each number = how many snapshots of that type to keep. Sanoid takes and prunes automatically via systemd timer.

```ini
[kashon01/d01-archiv]
  use_template = archiv

[kashon01/d02-lichni]
  use_template = lichni

[kashon01/d04-mc]
  use_template = mc

# d03-vm-backup: NO sanoid — Proxmox manages VZDump retention directly

[template_archiv]
  daily   = 0
  weekly  = 8    # 8 weeks of history — archival data changes slowly
  monthly = 0
  autosnap = yes
  autoprune = yes

[template_lichni]
  daily   = 7    # last 7 days
  weekly  = 4    # last 4 weeks
  monthly = 3    # last 3 months
  autosnap = yes
  autoprune = yes

[template_mc]
  daily   = 7    # last 7 days
  weekly  = 4    # last 4 weeks
  monthly = 0
  autosnap = yes
  autoprune = yes
```

> **`d03-vm-backup` note**: No sanoid snapshots on this dataset. Proxmox manages VZDump
> file retention directly (set keep last 3–5 per VM in Datacenter → Storage → vm-backup → Edit).
> ZFS snapshots on a backup dataset would silently hold deleted VZDump files alive,
> consuming large amounts of space — avoid entirely.

#### Using snapshots

Snapshots are accessible as a read-only directory tree — no special tools needed to read files:

```
/<mountpoint>/.zfs/snapshot/<snapshot-name>/
```

Example — browse and recover a file:
```bash
ls /mnt/archiv/.zfs/snapshot/
cp /mnt/archiv/.zfs/snapshot/autosnap_2025-10-10_daily/path/to/file.txt ~/recovered.txt
```

List all snapshots for a dataset:
```bash
zfs list -t snapshot kashon01/d01-archiv
```

Roll back an entire dataset to a snapshot (destructive — all changes since the snapshot are lost):
```bash
zfs rollback kashon01/d01-archiv@autosnap_2025-10-10_daily
```

Clone a snapshot into a new writable dataset (non-destructive — original dataset unchanged):
```bash
zfs clone kashon01/d01-archiv@autosnap_2025-10-10_daily kashon01/d01-archiv-recovered
```

#### Summary

| Component | Where | How reached |
|---|---|---|
| Tailscale | Proxmox baremetal (apt) + each VM | tailnet |
| Proxmox web GUI | VPS nginx → Proxmox baremetal `:8006` | tailnet only (`proxmox.vafla.eu`) |
| SSH — Proxmox baremetal | Proxmox baremetal | tailnet (`100.64.0.4`) + local LAN IP |
| SSH — home VM | `homeserver` | tailnet (`100.64.0.5`) + static LAN (`192.168.100.56`) |
| UPS USB | Direct to Proxmox baremetal | local USB on host |
| NUT server | Proxmox baremetal (apt) | bridge subnet (port 3493) |
| Homarr | home VM | tailnet-only (`homarr.vafla.eu`) |
| Shutdown | baremetal NUT → `shutdown -h now` | pve-guests.service stops VMs first |

---

## 14. Key decisions already made (with reasoning, for context)

- **nginx over Traefik/Caddy**: NixOS-native declarative setup — `services.nginx` +
  `security.acme` is the most mature combination in the NixOS ecosystem. Traefik's
  auto-discovery is irrelevant here; everything is already declared in Nix.
- **Headscale + DERP + Headplane on the VPS**: need a stable public address.
- **DNS-01 over HTTP-01 for ACME**: enables one wildcard cert; works for tailnet-only
  services too (no public port 80 needed for the challenge).
- **deSEC over ClouDNS for DNS hosting**: ClouDNS free plan has no API access.
  deSEC.io is a German non-profit with full REST API, auto DNSSEC, native lego support.
- **DNSSEC via deSEC**: auto-signs all zones. DS record at ClouDNS registrar (SHA-256 only —
  ClouDNS doesn't support SHA-384). systemd-resolved validates client-side.
- **Geo-blocking via db-ip.com**: MaxMind GeoLite2 requires registration; db-ip.com is
  free with no account. Monthly systemd timer for updates. Blocked: US, CN, RU, UA, BY, GB, IL.
- **Anubis on public HTTP services only, except headscale**: headscale exempt (API clients
  fail PoW). Tailnet-only services exempt — unreachable from internet.
- **fail2ban on VPS not home VM**: all public traffic enters the VPS. Home VM only sees
  the VPS tailscale IP — banning there would block the VPS itself.
- **agenix over sops-nix**: already integrated; per-file access control is sufficient
  for two hosts.
- **Headscale 0.29.4 via flake input**: nixpkgs stable had 0.28 which had an Android
  crash bug. Pinned to `github:juanfont/headscale/v0.29.4`; shows "dev" version string
  (expected — flake builds don't inject ldflags).
- **MC server runs inside the `homeserver` VM, not a separate VM**: simpler to manage;
  resource needs fit comfortably alongside everything else. `hosts/_mc-server.nix` and the
  README's `mc` host row are stale.
- **`homeserver` SSH reachable on LAN too, not tailnet-only**: parity with the Proxmox host,
  convenience without needing the tailnet up. Still key-only/no-password.
- **`fastvm` — dedicated LVM-thin pool for VM disks, isolated from `kashon01`**: a second
  SSD (`nvme1n1`) wiped into its own pool, never sharing a VG with the boot disk or the RAID mirror.
- **Authentik (central SSO) removed after initial deployment**: it was fully built and
  working — domain-level forward-auth, one login for every service via `auth.vafla.eu`.
  Removed because it broke native clients entirely: Jellyfin's TV/mobile apps, Calibre/OPDS
  readers, Subsonic music clients, `git` over HTTPS, Matrix clients — none of them can
  follow an HTML/cookie-based login redirect. Nearly every real service in the plan would
  have needed an Authentik exception anyway (Proxmox, Jellyfin, Calibre, Navidrome, and
  Enclosed all already did), making the shared SSO layer pointless overhead. Replaced with:
  each service's own login (where it has one) + Anubis (public bot/PoW protection) +
  fail2ban watching nginx logs for per-service brute-force patterns (§7).

---

## 15. Quick glossary (for a new session catching up)

- **Headscale** — open-source, self-hosted Tailscale control plane.
- **DERP** — Tailscale's relay fallback when direct WireGuard peer-to-peer fails.
- **Anubis** — proof-of-work HTTP challenge tool (TecharoHQ/anubis) blocking AI/scraper crawlers.
- **ACME / lego** — Let's Encrypt cert automation; lego is the client NixOS's `security.acme` uses.
- **NUT** — Network UPS Tools; monitors UPS hardware and triggers shutdown scripts.
- **Gatus** — declarative status page; monitors endpoints and shows health dashboard.
- **OCI containers / podman** — `virtualisation.oci-containers` runs plain Docker-image
  containers under NixOS; defaults to podman as the backend for `stateVersion ≥ 22.05`.
  Used for Enclosed (no native NixOS module exists for it).
