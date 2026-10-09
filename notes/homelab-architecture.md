# Homelab Architecture Reference

> Purpose of this file: a single source of truth describing the full self-hosted
> infrastructure — layout, request flow, and setup specifics — so a new chat/session (or a
> future version of me) can pick up context immediately without re-deriving it from scratch.
>
> Note: this doc intentionally covers **infrastructure only** (proxy, TLS, tailnet,
> firewall, bot protection, SSO plumbing) — not specific applications.

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
  services are exempt — they're unreachable from the internet and Authentik handles auth.
- **Authentik** as the SSO/forward-auth layer in front of all services that need a login
  wall: public-facing apps (git, media, etc.) and all tailnet-only private services.
  Static/read-only public services (status, maps, MC, landing pages) are Anubis-only.
  `headscale.vafla.eu` is exempt from both. **fail2ban runs on the VPS** watching nginx
  access logs — banning real attacker IPs at the VPS firewall before they reach the tailnet.
  (Running fail2ban on the home VM would be useless: all traffic arrives from the VPS
  tailscale IP, so banning would block the VPS itself, not the attacker.)
- Everything declared in **Nix** (NixOS), on a VM hosted under **Proxmox** at home.

---

## 2. Physical / infra layout

```
┌─────────────────────────────────────────────────────────────┐
│  Home: Proxmox host (Debian)                                 │
│    ├── Tailscale (apt) — for Proxmox GUI on tailnet          │
│    ├── NUT server (apt) — reads EG-UPS-033 USB directly      │
│    └── NixOS VM ("home-vm")                                  │
│          - Authentik + application services                   │
│          - PeaNUT (OCI) → connects to NUT on baremetal       │
│          - No public ports open. Reachable only over Tailscale│
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
    dns.base_domain = "tailnet.vafla.eu";
    derp.server = {
      enabled = true; region_id = 999;
      region_code = "home"; region_name = "Home";
      stun_listen_addr = "0.0.0.0:3478";
    };
    derp.urls = [];
  };
};
```

---

## 5. Geo-blocking

Country-level IP blocking on all **public-tier** nginx virtualHosts. Headscale exempt.

**Database:** db-ip.com free MMDB (no registration). Downloaded monthly via systemd timer
to `/var/lib/geoip/dbip-country-lite.mmdb`. `auto_reload 1d` hot-reloads without restart.

**Blocked:** US, CN, RU, UA, BY, GB.

```nginx
geoip2 /var/lib/geoip/dbip-country-lite.mmdb {
  auto_reload 1d;
  $geoip2_country_code default=XX country iso_code;
}
map $geoip2_country_code $geo_blocked {
  default 0;
  US 1; CN 1; RU 1; UA 1; BY 1; GB 1;
}
```

Add to each public tier-0b/0c virtualHost location:
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

**Home VM:** no public ports — tailnet only.

---

## 7. fail2ban

Runs on the **VPS**, watching nginx + sshd. Correct location because all public traffic
enters the VPS — real attacker IPs are only visible there.

```nix
services.fail2ban = {
  enable = true; maxretry = 5; bantime = "1h";
  bantime-increment.enable = true;
  jails = {
    sshd.settings = { enabled = true; port = "22"; filter = "sshd"; maxretry = 4; };
    nginx-http-auth.settings = { enabled = true; filter = "nginx-http-auth"; logpath = "/var/log/nginx/error.log"; };
    nginx-botsearch.settings = { enabled = true; filter = "nginx-botsearch"; logpath = "/var/log/nginx/access.log"; };
  };
};
```

---

## 8. Anubis — public services only

`services.anubis` is a native NixOS module. One instance per public service, each with
its own Unix socket. All instances and their nginx virtualHosts live in `modules/vps/anubis.nix`.

Socket path format: `BIND = "/run/anubis/anubis-<name>/anubis.sock"` (no `unix:` prefix in BIND;
nginx proxyPass uses `http://unix:/run/anubis/anubis-<name>/anubis.sock`).

nginx must be in the `anubis` group: `users.users.nginx.extraGroups = [ "anubis" ];`

**Exemptions:**
- `headscale.vafla.eu` — Tailscale API clients can't complete PoW challenges
- All tailnet-only (tier 1) services — unreachable from public internet

**Request chains by tier:**
```
# Tier 0a — headscale (bare)
nginx (TLS) → headscale

# Tier 0b — public static (Anubis only)
nginx (TLS) → Anubis → backend

# Tier 0c — public apps (Anubis + Authentik)
nginx (TLS) → Anubis → Authentik auth_request → backend

# Tier 1 — tailnet-only (Authentik only)
nginx (TLS, tailscale0) → Authentik auth_request → backend
```

---

## 9. Authentik SSO + fail2ban

Authentik provides OIDC/SAML/forward-auth. Runs **on the home VM**; nginx on the VPS
makes `auth_request` calls over the Tailscale tunnel.

Authentik applies to:
- **Tier 0c** — public apps (Anubis first, then Authentik)
- **Tier 1** — tailnet-only private services (Authentik only, no Anubis)

Exempt: `headscale.vafla.eu`, static/read-only public services (tier 0b).

**fail2ban** runs on the **VPS**, watching nginx access logs — not on the home VM (see §7).

Reusable nginx snippet:
```nix
authentikAuthRequest = ''
  auth_request /outpost.goauthentik.io/auth/nginx;
  error_page 401 = @goauthentik_proxy_signin;
  auth_request_set $auth_cookie $upstream_http_set_cookie;
  add_header Set-Cookie $auth_cookie;
'';
```

nginx virtualHost templates:
```nix
# Tier 0c — public, Anubis + Authentik
services.nginx.virtualHosts."<service>.vafla.eu" = {
  forceSSL = true; useACMEHost = "vafla.eu";
  locations."/" = {
    proxyPass = "http://unix:/run/anubis/anubis-<service>/anubis.sock";
    extraConfig = authentikAuthRequest;
  };
  locations."/outpost.goauthentik.io/" = {
    proxyPass = "http://<authentik-tailnet-ip>:9000/outpost.goauthentik.io/";
  };
};

# Tier 1 — tailnet-only, Authentik only
services.nginx.virtualHosts."<service>.vafla.eu" = {
  listenAddresses = [ "100.64.0.1" ];
  forceSSL = true; useACMEHost = "vafla.eu";
  locations."/" = {
    proxyPass = "http://<home-vm-tailscale-ip>:<port>";
    extraConfig = authentikAuthRequest;
  };
  locations."/outpost.goauthentik.io/" = {
    proxyPass = "http://<authentik-tailnet-ip>:9000/outpost.goauthentik.io/";
  };
};
```

---

## 10. Secrets management — agenix

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

---

## 11. Tailnet DNS — Technitium + DNS4EU fallback

Technitium runs on the home VM. Devices on the tailnet use it as their DNS server,
so `*.vafla.eu` resolves to VPS tailscale IP (for tailnet-only services) instead of
the public VPS IP.

Headscale `nameservers.global` = `[<technitium-tailscale-ip>, "86.54.11.100"]`
(Technitium primary, DNS4EU joindns4.eu unfiltered as fallback).

Local machine DNS: `86.54.11.100 86.54.11.200` (joindns4.eu — DNSSEC validating).

---

## 12. Service access tiers and service map

Four tiers. The distinction is made in DNS and nginx config.
TLS works for all — the cert covers `*.vafla.eu` + `vafla.eu` + `map.mc.vafla.eu`.

### Tier 0a — public, bare (headscale only)

| Subdomain | Service | Why exempt |
|---|---|---|
| `headscale.vafla.eu` | Headscale control plane | Tailscale API clients can't complete PoW |

### Tier 0b — public, Anubis only

deSEC A record → VPS public IP. Static/read-only — no login wall needed.

| Subdomain | Service | Backend |
|---|---|---|
| `vafla.eu` | MC server :25565 (TCP) + future CV/landing page | VPS (mc-proxy) / home VM |
| `mc.vafla.eu` | Static page (server info, modpack, voice chat, map link) | home VM |
| `map.mc.vafla.eu` | Bluemap (MC world map) | home VM |
| `bachkali.vafla.eu` | Gatus (status page) | VPS localhost:8081 |
| `radio-spektar.vafla.eu` | Static web page | home VM |
| `recepti.vafla.eu` | Static web page | home VM |
| `rechnik.vafla.eu` | TBD | home VM |

### Tier 0c — public, Anubis + Authentik + fail2ban

deSEC A record → VPS public IP. Apps that require a login wall.

| Subdomain | Service | Backend |
|---|---|---|
| `share.vafla.eu` | Microbin (paste / file share) | home VM |
| `git.vafla.eu` | Forgejo | home VM |
| `stream.vafla.eu` | Owncast | home VM |
| `dok.vafla.eu` | Cryptpad | home VM |
| `tube.vafla.eu` | Peertube | home VM |
| `tv.vafla.eu` | Jellyfin | home VM |
| `media.vafla.eu` | Immich | home VM |
| `vafla.eu` | Matrix homeserver (tuwunel, `/_matrix` path) | home VM |

### Tier 1 — tailnet-only, Authentik + fail2ban (no Anubis)

No deSEC record. Technitium resolves to VPS tailscale IP. nginx listens on `tailscale0` only.

| Subdomain | Service | Backend |
|---|---|---|
| `homarr.vafla.eu` | Homarr (dashboard) | home VM |
| `biblioteka.vafla.eu` | Calibre | home VM |
| `chertezh.vafla.eu` | Homelable | home VM |
| `webarhiv.vafla.eu` | Archivebox | home VM |
| `muzika.vafla.eu` | Feishin (Navidrome frontend) | home VM |
| `*arr.vafla.eu` | \*arr stack (TBD) | home VM |
| `dns.vafla.eu` | Technitium web UI | home VM |
| `headplane.vafla.eu` | Headplane (Headscale web UI) | VPS localhost:3000 |

### DNS summary

| Tier | deSEC record | Technitium record | nginx listens on | Anubis | Authentik |
|---|---|---|---|---|---|
| 0a — headscale | `A` → VPS public IP | `A` → VPS tailscale IP | public | no | no |
| 0b — public static | `A` → VPS public IP | `A` → VPS tailscale IP | public | yes | no |
| 0c — public apps | `A` → VPS public IP | `A` → VPS tailscale IP | public | yes | yes |
| 1 — tailnet | none | `A` → VPS tailscale IP | `tailscale0` only | no | yes |

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

# Tier 0c — public, Anubis + Authentik (see §9 for full template)

# Tier 1 — tailnet-only, Authentik only (see §9 for full template)
```

---

## 13. VPS setup plan

### Domain / service list

**deSEC A records** (all → VPS public IP):

| Record | Tier | Service | When |
|---|---|---|---|
| `vafla.eu` | 0b/0c | MC server :25565 (TCP) + Matrix `/_matrix` + future landing page | Stage 1 |
| `headscale.vafla.eu` | 0a | Headscale control plane | Stage 1 ✓ |
| `bachkali.vafla.eu` | 0b | Gatus | Stage 1 ✓ |
| `mc.vafla.eu` | 0b | Static page | Stage 5 |
| `map.mc.vafla.eu` | 0b | Bluemap | Stage 5 |
| `radio-spektar.vafla.eu` | 0b | Static web page | Stage 5 |
| `recepti.vafla.eu` | 0b | Static web page | Stage 5 |
| `rechnik.vafla.eu` | 0b | TBD | Stage 5 |
| `share.vafla.eu` | 0c | Microbin | Stage 5 |
| `git.vafla.eu` | 0c | Forgejo | Stage 5 |
| `stream.vafla.eu` | 0c | Owncast | Stage 5 |
| `dok.vafla.eu` | 0c | Cryptpad | Stage 5 |
| `tube.vafla.eu` | 0c | Peertube | Stage 5 |
| `tv.vafla.eu` | 0c | Jellyfin | Stage 5 |
| `media.vafla.eu` | 0c | Immich | Stage 5 |

**Technitium records — nginx-proxied services** (all → VPS tailscale IP, Stage 5):

| Record | Tier | Service |
|---|---|---|
| `homarr.vafla.eu` | 1 | Homarr |
| `biblioteka.vafla.eu` | 1 | Calibre |
| `chertezh.vafla.eu` | 1 | Homelable |
| `webarhiv.vafla.eu` | 1 | Archivebox |
| `muzika.vafla.eu` | 1 | Feishin (Navidrome) |
| `matrix.vafla.eu` | 0c | Matrix (also needs deSEC for `/_matrix`) |
| `*arr.vafla.eu` | 1 | \*arr stack (TBD) |
| `dns.vafla.eu` | 1 | Technitium web UI |
| `headplane.vafla.eu` | 1 | Headplane — VPS-local backend |
| `proxmox.vafla.eu` | 1 | Proxmox web GUI — tailnet only, Authentik, no Anubis; nginx → Proxmox baremetal tailscale IP:8006 |

**Technitium records — direct machine SSH** (→ each machine's own tailscale IP, bypass nginx entirely):

| Record | Resolves to | Purpose |
|---|---|---|
| `baremetalvm.vafla.eu` | Proxmox baremetal tailscale IP | SSH to Proxmox host — no deSEC record |
| `hsvm.vafla.eu` | home VM tailscale IP | SSH to home VM — no deSEC record |
| `mcvm.vafla.eu` | MC VM tailscale IP | SSH to MC VM — no deSEC record |

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
- [x] `modules/vps/gatus.nix` — Gatus status page on `bachkali.vafla.eu:8081`; all endpoints
      pre-configured (disabled until deployed), grouped VPS / MC / Home Server
- [x] `modules/vps/anubis.nix` — Anubis in front of Gatus; nginx group fix; geo-blocking
- [ ] `modules/vps/headplane.nix` — deferred to Stage 5; needs home VM up for Authentik
      (behind Anubis + Authentik + fail2ban, tailnet-only, `listenAddresses`)
- [ ] `modules/vps/mc-proxy.nix` — TCP stream proxy for Minecraft :25565; deferred to Stage 5

### Stage 3 — first deploy and verify ✓

- [x] Deploy to VPS
- [x] Confirm headscale, nginx, tailscaled, fail2ban, gatus, anubis running
- [x] Confirm wildcard cert issued
- [x] Create Headscale user: `headscale users create koko`
- [x] Join VPS to its own tailnet
- [ ] Note VPS tailscale IP — fill into `mc-proxy.nix` and tier-1 `listenAddresses`

### Stage 4 — enroll devices (in progress)

- [x] Join kt480 laptop — enrolled in tailnet
      > joindns4.eu had stale NS cache after deSEC migration; temporarily used 1.1.1.1.
      > Cache expired — switched back to `86.54.11.100 86.54.11.200`. ✓
- [x] Join phone (Android, kthinkphone) — enrolled
      > Headscale 0.28 had Android crash bug; fixed by upgrading to 0.29.4 via flake input.
- [~] Join Windows machine — skipped for now
- [ ] Join home VM once provisioned
- [ ] Note home VM tailscale IP — fill into `headscale.nix` `nameservers.global`
      and Authentik `proxyPass` placeholders

### Stage 5 — service layer (after home VM is up with Authentik + Technitium)

- [ ] Provision home VM on Proxmox (NixOS)
- [ ] Configure SSH on home VM: tailnet-only (`ListenAddress <home-vm-tailscale-ip>`);
      add authorized keys; no password auth; no local network SSH (tailnet is the only path)
- [ ] Set up Authentik on home VM
- [ ] Set up Technitium on home VM
- [ ] Fill in home VM tailscale IP in `headscale.nix` `nameservers.global`
- [ ] Fill in VPS tailscale IP in tier-1 nginx `listenAddresses`
- [ ] Fill in MC VM tailscale IP in `mc-proxy.nix`; wire into vps.nix
- [ ] Wire up `modules/vps/headplane.nix` — tailnet-only (`headplane.vafla.eu`),
      behind Anubis + Authentik + fail2ban; `listenAddresses = [ "100.64.0.1" ]`
- [ ] Add Anubis instances per service (`modules/vps/anubis.nix`)
- [ ] Add nginx virtualHosts for tier-0b/0c services
- [ ] Add nginx virtualHosts for tier-1 services
- [ ] Add Authentik outpost `proxyPass` blocks
- [ ] Add deSEC A records for all tier-0b and tier-0c subdomains → VPS public IP
- [ ] Add Technitium DNS records for all tier-1 subdomains → VPS tailscale IP

### Stage 6 — Proxmox host + UPS (after home VM is up)

- [ ] Install Tailscale on Proxmox Debian host (`apt install tailscale`);
      register with Headscale
- [ ] Add Technitium records:
      `proxmox.vafla.eu` → VPS tailscale IP (tier-1 web GUI via nginx + Authentik);
      `baremetalvm.vafla.eu` → Proxmox baremetal tailscale IP (direct SSH)
- [ ] Add nginx virtualHost for `proxmox.vafla.eu` on VPS (tier-1, Authentik, proxyWebsockets,
      proxyPass → Proxmox baremetal tailscale IP:8006)
- [ ] Configure SSH on Proxmox baremetal: listen on tailnet IP + local LAN IP;
      tailnet SSH: `ssh root@baremetalvm.vafla.eu`;
      local SSH: `ssh root@<lan-ip>` (fallback if tailnet is down);
      no password auth; add authorized keys
- [ ] Install NUT on Proxmox baremetal (`apt install nut`); configure `/etc/nut/` for EG-UPS-033;
      listen on `0.0.0.0:3493` (firewall-restricted to home VM bridge IP only);
      `SHUTDOWNCMD = "shutdown -h now"` — Proxmox `pve-guests.service` handles graceful VM stop
- [ ] Add PeaNUT OCI container to home VM (`virtualisation.oci-containers`);
      point `NUT_HOST` to Proxmox bridge IP (e.g. `10.0.0.1`) or Proxmox tailscale IP
- [ ] Configure Homarr PeaNUT widget → `http://localhost:8082`
- [ ] See `notes/ups/` for baremetal NUT config and shutdown script

---

## 14. Open items / not yet finalized

### Proxmox host on tailnet + UPS + PeaNUT plan

#### Layout

```
EG-UPS-033 (USB — direct, no passthrough)
      │
Proxmox baremetal (Debian)
  ├── Tailscale (apt) — tailnet member, for Proxmox GUI access
  ├── NUT server (apt) — reads UPS via USB; SHUTDOWNCMD="shutdown -h now"
  │     └── Proxmox pve-guests.service gracefully stops all VMs on host shutdown
  └── home VM (NixOS)
        ├── Tailscale (tailnet member)
        ├── PeaNUT (OCI container) — connects to NUT on baremetal bridge IP
        └── Homarr — PeaNUT widget on localhost (tier-1, behind Authentik)
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

Add Technitium records:
- `proxmox.vafla.eu` → VPS tailscale IP — nginx proxies to Proxmox baremetal `:8006`, behind Authentik (`proxyWebsockets = true` required for the console)
- `baremetalvm.vafla.eu` → Proxmox baremetal tailscale IP — direct SSH only

Access GUI at `https://proxmox.vafla.eu` on the tailnet (tier-1, Authentik gated).

#### Step 2 — NUT on Proxmox baremetal (Debian, `apt`)

USB is plugged directly into the Proxmox host — no passthrough needed.
See `notes/ups/` for the exact `/etc/nut/` config files and the shutdown script.

Key points:
- `upsd.conf`: listen on the VM bridge IP (e.g. `10.0.0.1`) so PeaNUT on the home VM
  can reach it; firewall-restrict port 3493 to the bridge subnet only
- `upsmon.conf`: `SHUTDOWNCMD "/sbin/shutdown -h now"`
- Proxmox's `pve-guests.service` fires during systemd shutdown and stops all VMs
  gracefully before the host powers off — no custom Proxmox API scripting needed

#### Step 3 — PeaNUT on the home VM

PeaNUT is not in nixpkgs — OCI container. NUT is on the baremetal, so point
`NUT_HOST` at the Proxmox bridge IP (or Proxmox tailscale IP):

```nix
virtualisation.oci-containers.containers.peanut = {
  image = "ghcr.io/brandawg93/peanut:latest";
  ports = [ "8082:8080" ];
  environment = {
    NUT_HOST = "<proxmox-bridge-ip>";  # e.g. 10.0.0.1 — fill in at deploy time
    NUT_PORT = "3493";
    NUT_USER = "monitor";
    NUT_PASS = "<from agenix secret>";
  };
};
```

#### Step 4 — Homarr widget

Homarr is tier-1 (tailnet-only, behind Authentik at `homarr.vafla.eu`).
PeaNUT has no vhost, no DNS entry, no external access — purely internal.
The only way to see UPS data is through the Homarr dashboard.

In Homarr: add PeaNUT widget → URL `http://localhost:8082`.

#### Summary

| Component | Where | How reached |
|---|---|---|
| Tailscale | Proxmox baremetal (apt) + each VM | tailnet |
| Proxmox web GUI | VPS nginx → Proxmox baremetal `:8006` | tailnet only (`proxmox.vafla.eu`), Authentik |
| SSH — Proxmox baremetal | Proxmox baremetal | tailnet (`baremetalvm.vafla.eu`) + local LAN IP |
| SSH — home VM | home VM | tailnet only (`hsvm.vafla.eu`) |
| SSH — MC VM | MC VM | tailnet only (`mcvm.vafla.eu`) |
| UPS USB | Direct to Proxmox baremetal | local USB on host |
| NUT server | Proxmox baremetal (apt) | bridge subnet (port 3493) |
| PeaNUT | home VM (OCI container) | localhost only — Homarr widget |
| Homarr | home VM | tailnet, behind Authentik (`homarr.vafla.eu`) |
| Shutdown | baremetal NUT → `shutdown -h now` | pve-guests.service stops VMs first |

---

## 15. Key decisions already made (with reasoning, for context)

- **nginx over Traefik/Caddy**: NixOS-native declarative setup — `services.nginx` +
  `security.acme` is the most mature combination in the NixOS ecosystem. Traefik's
  auto-discovery is irrelevant here; everything is already declared in Nix.
- **Authentik over Keycloak**: ~10x lighter on RAM (250-350MB vs 4GB+), native
  forward-auth built in. Keycloak only makes sense with enterprise LDAP/AD needs.
- **Headscale + DERP + Headplane on the VPS, Authentik on the home VM**: Headscale/DERP
  need a stable public address. Authentik stays on the home VM — running it on the VPS
  would put PostgreSQL + Redis on cloud hardware and store credentials on a third party.
- **DNS-01 over HTTP-01 for ACME**: enables one wildcard cert; works for tailnet-only
  services too (no public port 80 needed for the challenge).
- **deSEC over ClouDNS for DNS hosting**: ClouDNS free plan has no API access.
  deSEC.io is a German non-profit with full REST API, auto DNSSEC, native lego support.
- **DNSSEC via deSEC**: auto-signs all zones. DS record at ClouDNS registrar (SHA-256 only —
  ClouDNS doesn't support SHA-384). systemd-resolved validates client-side.
- **Geo-blocking via db-ip.com**: MaxMind GeoLite2 requires registration; db-ip.com is
  free with no account. Monthly systemd timer for updates. Blocked: US, CN, RU, UA, BY, GB.
- **Anubis on public HTTP services only, except headscale**: headscale exempt (API clients
  fail PoW). Tailnet-only services exempt — unreachable from internet.
- **Authentik on all services except headscale and tier-0b static**: static/read-only
  public services are Anubis-only. All apps (tier 0c + tier 1) use Authentik forward-auth.
  fail2ban on the VPS (not home VM) — only the VPS sees real client IPs.
- **fail2ban on VPS not home VM**: all public traffic enters the VPS. Home VM only sees
  the VPS tailscale IP — banning there would block the VPS itself.
- **agenix over sops-nix**: already integrated; per-file access control is sufficient
  for two hosts.
- **Headscale 0.29.4 via flake input**: nixpkgs stable had 0.28 which had an Android
  crash bug. Pinned to `github:juanfont/headscale/v0.29.4`; shows "dev" version string
  (expected — flake builds don't inject ldflags).

---

## 16. Quick glossary (for a new session catching up)

- **Authentik** — self-hosted IdP (OIDC/SAML) + forward-auth proxy provider.
- **Headscale** — open-source, self-hosted Tailscale control plane.
- **DERP** — Tailscale's relay fallback when direct WireGuard peer-to-peer fails.
- **Anubis** — proof-of-work HTTP challenge tool (TecharoHQ/anubis) blocking AI/scraper crawlers.
- **ACME / lego** — Let's Encrypt cert automation; lego is the client NixOS's `security.acme` uses.
- **NUT** — Network UPS Tools; monitors UPS hardware and triggers shutdown scripts.
- **PeaNUT** — web UI for NUT; Homarr-compatible widget for UPS status display.
- **Gatus** — declarative status page; monitors endpoints and shows health dashboard.
