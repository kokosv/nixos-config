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
│          - Authentik (native Postgres+Redis, server+worker    │
│            as OCI/podman containers) — deployed, working       │
│          - Technitium DNS — deployed, `vafla.eu` zone live    │
│          - No public ports open. SSH reachable over tailnet   │
│            and LAN (not tailnet-only, unlike the original     │
│            plan — see §15)                                    │
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

**Home VM ("homeserver"):** no public ports. SSH listens on both `100.64.0.5` (tailnet)
and `192.168.100.56` (static LAN, gateway `192.168.100.1`) — deliberately not tailnet-only
like originally planned; see §15 for why. `networking.useDHCP = false`, static address set
declaratively so `sshd`'s `listenAddresses` stays valid across reboots.

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

**Deployed.** No native NixOS service module exists — only a nixpkgs package. Deployment
(`modules/homeserver/authentik.nix`): native `services.postgresql` +
`services.redis.servers.authentik`, with `authentik-server`/`authentik-worker` as
`--network=host` podman containers (`ghcr.io/goauthentik/server:2025.12.6`) talking to
Postgres/Redis over `127.0.0.1`.

**Gotchas:**
- `ensureUsers` can't set a Postgres password declaratively — oneshot service
  `authentik-postgres-password` runs `ALTER ROLE` from the agenix secret on boot, ordered
  `after = [ "postgresql.service" "postgresql-setup.service" ]` (user creation happens in
  the latter unit, not the former).
- Container runs as UID 1000; with podman `--network=host` that's UID 1000 on the host too
  — `/var/lib/authentik/{media,templates,certs}` must be `chown 1000:1000`, not root.
- `akadmin`'s password is random unless `AUTHENTIK_BOOTSTRAP_EMAIL`/`_PASSWORD` env vars
  are set (agenix secret `authentik-bootstrap.age`). No bootstrap username var exists —
  login is always `akadmin`.

**Domain-level forward auth** — one provider covers every `*.vafla.eu` subdomain via a
shared SSO cookie:
- Provider: Proxy Provider, mode **Forward auth (domain level)**
- **Authentication URL**: `https://auth.vafla.eu` (externally-reachable hostname, not the
  internal `100.64.0.5:9000` backend address)
- **Cookie domain**: `vafla.eu` — must be the parent/apex domain, not `auth.vafla.eu` itself
- One Application (`vafla.eu`) bound to the embedded outpost — no per-service Application needed

`auth.vafla.eu` is the only door — a separate tailnet-only `authentik.vafla.eu` was removed
as redundant. Since both led to the same app, `akadmin`'s admin UI (`/if/admin/`) is
technically reachable via the public `auth.vafla.eu` too, protected by Anubis + credentials
+ Authentik's own rate-limiting, not a network-level restriction.

Authentik applies to:
- **Tier 0c** — public apps (Anubis first, then Authentik)
- **Tier 1** — tailnet-only private services (Authentik only, no Anubis) — **except
  `proxmox.vafla.eu`**, an explicit exception with no Authentik wrapper (Proxmox has its
  own login; the added friction was judged unnecessary for a single-admin box)

Exempt: `headscale.vafla.eu`, `auth.vafla.eu` itself (circular), static/read-only public
services (tier 0b).

**fail2ban** runs on the **VPS**, watching nginx access logs — not on the home VM (see §7).

Reusable nginx snippet (as actually deployed — see `modules/vps/technitium-proxy.nix` for
a full working example):
```nix
locations."/" = {
  proxyPass = "http://100.64.0.5:<port>"; # or an Anubis socket for tier 0c
  extraConfig = ''
    auth_request /outpost.goauthentik.io/auth/nginx;
    error_page 401 = @authentik_redirect;
    auth_request_set $auth_cookie $upstream_http_set_cookie;
    add_header Set-Cookie $auth_cookie;
    auth_request_set $authentik_username $upstream_http_x_authentik_username;
    auth_request_set $authentik_groups   $upstream_http_x_authentik_groups;
    proxy_set_header X-authentik-username $authentik_username;
    proxy_set_header X-authentik-groups   $authentik_groups;
  '';
};
locations."/outpost.goauthentik.io/" = {
  proxyPass = "http://100.64.0.5:9000/outpost.goauthentik.io/";
  extraConfig = ''
    proxy_set_header X-Original-URL $scheme://$http_host$request_uri;
    add_header Set-Cookie $auth_cookie;
    auth_request_set $auth_cookie $upstream_http_set_cookie;
  '';
};
locations."@authentik_redirect" = {
  extraConfig = ''
    return 302 /outpost.goauthentik.io/start?rd=$scheme://$http_host$request_uri;
  '';
};
```

**Unauthenticated request flow**: `auth_request` → 401 → redirect to
`<service>/outpost.goauthentik.io/start?rd=...` → Authentik redirects to `auth.vafla.eu` →
Anubis → login → cookie set on `.vafla.eu` → redirect back → `auth_request` passes →
proxied to the service's own Anubis instance → backend. Cookie persists across subsequent
visits, so this chain only runs once per login.

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
- `secrets/authentik-secret-key.age` — `AUTHENTIK_SECRET_KEY=...` (homeserver)
- `secrets/authentik-postgres-password.age` — `AUTHENTIK_POSTGRESQL__PASSWORD=...` (homeserver)
- `secrets/authentik-bootstrap.age` — `AUTHENTIK_BOOTSTRAP_EMAIL=...` + `AUTHENTIK_BOOTSTRAP_PASSWORD=...` (homeserver)

`homeserver` is now a registered agenix host (added to `allHosts` in `agenix-rules.nix`).

---

## 11. Tailnet DNS — Technitium + DNS4EU fallback

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
- `headscale.vafla.eu` → `31.70.105.226` (VPS **public** IP — needed for DERP bootstrap,
  see §4; this is the one record that must NOT point at the tailscale IP)

Everything else (public tier 0a/0b/0c subdomains, `auth.vafla.eu`) needs no entry — the
Forwarder zone handles it automatically. Only add a new zone here when a subdomain has no
public DNS record at all.

Local machine DNS (non-tailnet): `86.54.11.100 86.54.11.200` (joindns4.eu — DNSSEC validating).

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
| `rechnik.vafla.eu` | TBD | home VM |
| `auth.vafla.eu` | Authentik SSO login portal — **deployed**, no Authentik wrapper (circular) | home VM (`100.64.0.5:9000`) |

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
| `knigi.vafla.eu` | Calibre | home VM |
| `muzika.vafla.eu` | Feishin (Navidrome frontend) | home VM |
| `*arr.vafla.eu` | \*arr stack (TBD) | home VM |
| `dns.vafla.eu` | Technitium web UI — **deployed** | home VM (`100.64.0.5:5380`) |
| `headplane.vafla.eu` | Headplane (Headscale web UI) | VPS localhost:3000 |
| `proxmox.vafla.eu` | Proxmox web GUI — **deployed, no Authentik** (has its own login) | Proxmox baremetal (`100.64.0.4:8006`) |

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

### Implementation order

One at a time, each built end-to-end (app + nginx vhost + Anubis + Authentik outpost +
DNS record, per its own tier below) and tested before moving to the next:

1. `headplane.vafla.eu` — tier 1
2. `share.vafla.eu` (Microbin) — tier 0c
3. `dok.vafla.eu` (Cryptpad) — tier 0c
4. `stream.vafla.eu` (Owncast) — tier 0c
5. `knigi.vafla.eu` (Calibre) — tier 1
6. `homarr.vafla.eu` (Homarr) — tier 1
7. MC server + `map.mc.vafla.eu` (Bluemap, tier 0b) + `mc.vafla.eu` (static info page, tier 0b)
8. `rechnik.vafla.eu` — tier 0b
9. `git.vafla.eu` (Forgejo) — tier 0c
10. `vafla.eu` `/_matrix` (Matrix) — tier 0c
11. `*arr.vafla.eu` stack (tier 1) + `tv.vafla.eu` (Jellyfin, tier 0c) — needs planning first
12. `tube.vafla.eu` (Peertube) — tier 0c
13. `media.vafla.eu` (Immich) — tier 0c
14. `muzika.vafla.eu` (Feishin/Navidrome) — tier 1

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
| `knigi.vafla.eu` | 1 | Calibre |
| `muzika.vafla.eu` | 1 | Feishin (Navidrome) |
| `matrix.vafla.eu` | 0c | Matrix (also needs deSEC for `/_matrix`) |
| `*arr.vafla.eu` | 1 | \*arr stack (TBD) |
| `dns.vafla.eu` | 1 | Technitium web UI |
| `headplane.vafla.eu` | 1 | Headplane — VPS-local backend |
| `proxmox.vafla.eu` | 1 | Proxmox web GUI — tailnet only, Authentik, no Anubis; nginx → Proxmox baremetal tailscale IP:8006 |

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
      VPS / MC / Home Server. Authentik-gated endpoints check the backend directly over
      tailnet (`100.64.0.5:<port>`), not the public hostname — `auth_request` would
      otherwise intercept before the backend, making the check meaningless. Cert
      expiration checked only on Headscale (shared wildcard cert, redundant elsewhere).
- [x] `modules/vps/anubis.nix` — Anubis in front of Gatus; nginx group fix; geo-blocking
- [ ] `modules/vps/headplane.nix` — deferred to Stage 5; needs home VM up for Authentik
      (behind Anubis + Authentik + fail2ban, tailnet-only, `listenAddresses`)
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

### Stage 5 — service layer (after home VM is up with Authentik + Technitium)

- [x] Provision home VM on Proxmox (NixOS) — named `homeserver`, `hosts/homeserver/`.
      q35 + OVMF/UEFI (Secure Boot pre-enroll off), 10 cores (`host` type), 26-30GB RAM,
      256GB disk on `fastvm`. MC server runs as a service inside this VM, not a separate VM.
- [x] Configure SSH on home VM — tailnet (`100.64.0.5`) + static LAN (`192.168.100.56`),
      key-only, `PermitRootLogin = "prohibit-password"` (see §15)
- [x] Set up Authentik on home VM — `modules/homeserver/authentik.nix` (see §9)
- [x] Set up Technitium on home VM — `modules/homeserver/technitium.nix` (see §11)
- [x] Fill in home VM tailscale IP in `headscale.nix` `nameservers.global` (`100.64.0.5`)
- [x] Fill in VPS tailscale IP in tier-1 nginx `listenAddresses` (`100.64.0.1`) — used by
      `dns.vafla.eu` and `proxmox.vafla.eu` so far
- [ ] Fill in home VM tailscale IP in `mc-proxy.nix` (MC server runs on home VM); wire into vps.nix
- [ ] Wire up `modules/vps/headplane.nix` — tailnet-only (`headplane.vafla.eu`),
      behind Anubis + Authentik + fail2ban; `listenAddresses = [ "100.64.0.1" ]`;
      the `<authentik-tailnet-ip>` placeholder can now be filled with `100.64.0.5`
- [~] Add Anubis instances per service (`modules/vps/anubis.nix`) — done for `auth.vafla.eu`;
      rest still pending per-service
- [ ] Add nginx virtualHosts for tier-0b/0c services
- [x] Add nginx virtualHosts for tier-1 services — `dns.vafla.eu`
      (`modules/vps/technitium-proxy.nix`) and `proxmox.vafla.eu`
      (`modules/vps/proxmox-proxy.nix`, no-Authentik exception) done; rest pending
- [x] Add Authentik outpost `proxyPass` blocks — done for `dns.vafla.eu`; template known,
      same pattern for the rest
- [ ] Add deSEC A records for all tier-0b and tier-0c subdomains → VPS public IP
- [~] Add Technitium DNS records for all tier-1 subdomains → VPS tailscale IP — `dns` and
      `proxmox` done; rest pending

### Stage 6 — Proxmox host + UPS + ZFS storage (after home VM is up)

#### Proxmox host basics

- [x] **BIOS**: AC Power Loss → **Last State**
- [x] Install Tailscale on Proxmox Debian host (`apt install tailscale` — needed the
      official Tailscale apt repo first, not in Debian's default repos);
      registered with Headscale — `100.64.0.4`
- [x] Add Technitium record: `proxmox.vafla.eu` → VPS tailscale IP (`100.64.0.1`)
- [x] Add nginx virtualHost for `proxmox.vafla.eu` on VPS — **no Authentik** (deliberate
      exception, see §9/§12), proxyWebsockets, proxyPass → `100.64.0.4:8006`,
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
- [ ] Install sanoid (`apt install sanoid`); write `/etc/sanoid/sanoid.conf` (see §14 for full config);
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
- [ ] Add VirtioFS shares to **home VM** (VM → Hardware → Add → VirtioFS) — verify whether
      this was done during VM creation or still needs doing:
      ```
      mapping: d01-archiv,  tag: d01-archiv
      mapping: d02-lichni,  tag: d02-lichni
      mapping: d04-mc,      tag: d04-mc
      ```
- [ ] Declare mounts in **home VM** NixOS config:
      ```nix
      fileSystems."/d01-archiv" = { device = "d01-archiv"; fsType = "virtiofs"; };
      fileSystems."/d02-lichni" = { device = "d02-lichni"; fsType = "virtiofs"; };
      fileSystems."/d04-mc"     = { device = "d04-mc";     fsType = "virtiofs"; };
      ```

---

## 14. Open items / not yet finalized

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
baremetal `:8006`, no Authentik (`proxyWebsockets = true` required for the console).

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
| Proxmox web GUI | VPS nginx → Proxmox baremetal `:8006` | tailnet only (`proxmox.vafla.eu`), **no Authentik** (exception) |
| SSH — Proxmox baremetal | Proxmox baremetal | tailnet (`100.64.0.4`) + local LAN IP |
| SSH — home VM | `homeserver` | tailnet (`100.64.0.5`) + static LAN (`192.168.100.56`) |
| UPS USB | Direct to Proxmox baremetal | local USB on host |
| NUT server | Proxmox baremetal (apt) | bridge subnet (port 3493) |
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
- **MC server runs inside the `homeserver` VM, not a separate VM**: simpler to manage;
  resource needs fit comfortably alongside everything else. `hosts/_mc-server.nix` and the
  README's `mc` host row are stale.
- **`homeserver` SSH reachable on LAN too, not tailnet-only**: parity with the Proxmox host,
  convenience without needing the tailnet up. Still key-only/no-password.
- **`fastvm` — dedicated LVM-thin pool for VM disks, isolated from `kashon01`**: a second
  SSD (`nvme1n1`) wiped into its own pool, never sharing a VG with the boot disk or the RAID mirror.
- **Authentik: native Postgres/Redis + OCI containers, not a native NixOS module**: no
  `services.authentik` module exists in nixpkgs. See §9.
- **`auth.vafla.eu` serves both the SSO redirect target and direct admin login** — the
  redundant tailnet-only `authentik.vafla.eu` was removed. See §9 for the tradeoff.
- **`proxmox.vafla.eu` is an explicit Authentik exception**: has its own login already.

---

## 16. Quick glossary (for a new session catching up)

- **Authentik** — self-hosted IdP (OIDC/SAML) + forward-auth proxy provider.
- **Headscale** — open-source, self-hosted Tailscale control plane.
- **DERP** — Tailscale's relay fallback when direct WireGuard peer-to-peer fails.
- **Anubis** — proof-of-work HTTP challenge tool (TecharoHQ/anubis) blocking AI/scraper crawlers.
- **ACME / lego** — Let's Encrypt cert automation; lego is the client NixOS's `security.acme` uses.
- **NUT** — Network UPS Tools; monitors UPS hardware and triggers shutdown scripts.
- **Gatus** — declarative status page; monitors endpoints and shows health dashboard.
- **OCI containers / podman** — `virtualisation.oci-containers` runs plain Docker-image
  containers under NixOS; defaults to podman as the backend for `stateVersion ≥ 22.05`.
  Used for Authentik's server/worker (no native NixOS module exists for those).
- **Forward auth (domain level)** — an Authentik Proxy Provider mode where one provider
  protects every subdomain under a parent domain via a shared SSO cookie, instead of one
  provider per protected application.
