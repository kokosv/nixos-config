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

Proxmox host ("monolit") setup and everything baremetal — not Nix-reproducible — is
documented separately in `notes/proxmox-baremetal.md`.

---

## 3. DNS & TLS

- **Registrar:** ClouDNS (domain registration only)
- **DNS hosting:** deSEC.io (free, DNSSEC auto-signed, REST API for lego)
- **ACME:** ZeroSSL (EU/Austria-based) DNS-01 via lego (`dnsProvider = "desec"`), EAB required
  (`LEGO_EAB_KID`/`LEGO_EAB_HMAC` in `secrets/zerossl-acme-env.age`)
- **Cert:** `*.vafla.eu` + `vafla.eu` + `map.mc.vafla.eu` — one wildcard covers all subdomains
- **DNSSEC:** deSEC auto-signs; DS record (SHA-256) added at ClouDNS registrar
- **HSTS:** set site-wide via `commonHttpConfig` in `modules/vps/nginx.nix` (not included
  by `recommendedTlsSettings`, has to be added explicitly)

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

> nginx's `recommendedProxySettings` sets a global 60s `proxy_read_timeout`, which kills
> the long-lived DERP relay connection every minute (clients see this as a recurring
> "no-derp-connection" health warning). Fixed with a dedicated `locations."/derp"` block
> on `headscale.vafla.eu` (`modules/vps/headscale.nix`) with `proxy_read_timeout 1d;` /
> `proxy_send_timeout 1d;`, leaving the rest of the API at the normal 60s.

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

**Catch-all default vhost** (`modules/vps/nginx.nix`, `virtualHosts."_default"`, `default =
true;`): any Host header that doesn't match a configured vhost gets `444` (connection
closed) instead of silently falling through to whichever vhost is declared first. Without
this, a removed or typo'd domain would serve whatever service happens to be first in the
config (bit us once with `auth.vafla.eu` falling through to Gatus after removal).

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
- `secrets/nazhivo-htpasswd.age` — nginx `auth_basic_user_file` for `nazhivo.vafla.eu`
  (`user:<apr1-hash>`, VPS)

`homeserver` is a registered agenix host (in `allHosts` in `agenix-rules.nix`).

---

## 10. Tailnet DNS — Technitium as sole resolver, forwarding to DNS4EU

Technitium runs on the home VM (`homeserver`, `100.64.0.5`) via `services.technitium-dns-server`
(`modules/homeserver/technitium.nix`). `openFirewall = false` — `tailscale0` is already trusted.

Headscale (`modules/vps/headscale.nix`): `nameservers.global = [ "100.64.0.5" ]` — every
tailnet device sends **all** DNS queries to Technitium, not just `vafla.eu`. Technitium
itself forwards anything outside its own zones to DNS4EU, set via Technitium's own admin
UI (Settings → DNS → Forwarders), not declared in Nix:
- Protocol: **DNS-over-TLS**, forwarders `unfiltered.joindns4.eu (86.54.11.100)` and
  `unfiltered.joindns4.eu (86.54.11.200)` — encrypts the one remaining plaintext leg
  (Technitium → DNS4EU) so the home ISP can't see it either. Verified via packet capture
  on homeserver: all traffic to DNS4EU is TCP/853 (TLS), no plaintext port 53.
- Blocking: enabled, type **NX Domain**.
- Query logging: enabled.

Chosen this way (Technitium as the sole pushed resolver, forwarding internally) so
Technitium's blocking/logging apply to all tailnet DNS traffic, not just `vafla.eu`.

> Originally this was split-DNS (`nameservers.split."vafla.eu"` + a separate
> `nameservers.global` for DNS4EU) specifically to avoid making Technitium a single
> point of failure for all tailnet DNS. Switched because Tailscale doesn't support true
> ordered primary/fallback for multiple global nameservers — listing both Technitium and
> DNS4EU in `nameservers.global` just non-deterministically load-balances between them per
> query, not "try Technitium, fall back to DNS4EU." Accepted trade-off: if the homeserver
> VM is down, **all** tailnet DNS breaks now, not just `vafla.eu` — there's no
> automatic client-side failover either way with Tailscale's current DNS push model.

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
| `vafla.eu` | MC server :25565 (TCP) + future landing page | VPS (mc-proxy) / home VM |
| `mc.vafla.eu` | Static page (server info, modpack, voice chat, map link) | home VM |
| `map.mc.vafla.eu` | Bluemap (MC world map) | home VM |
| `bachkali.vafla.eu` | Gatus (status page) | VPS localhost:8081 |
| `rechnik.vafla.eu` | TBD | home VM |
| `taina.vafla.eu` | Enclosed (secure note sharing) — **deployed**, own account-gated creation | home VM (`100.64.0.5:8787`) |
| `git.vafla.eu` | Forgejo | home VM |
| `nazhivo.vafla.eu` | Owncast — **deployed**. No hardware encoding (VM has no real GPU, software x264 only); 3 re-encoded quality variants (1080p/720p/480p, sized for ~5 viewers). Directory listing, search indexing, and Fediverse federation all disabled. nginx `auth_basic` in front of the whole vhost (`secrets/nazhivo-htpasswd.age`) — single shared login, not open to random visitors | home VM (`100.64.0.5:8080`) |
| `dok.vafla.eu` | Cryptpad — **deployed**. Anonymous pad creation/storage blocked (`customize/application_config.js`). Registration closes via admin panel after creating one account — manual, can't be pre-configured. Single-user usage, sharing via direct link only. **Known limitation**: importing a real `.xlsx`/`.ods`/`.docx`/`.pptx` into a new sheet/doc/presentation produces a blank document — nixpkgs's bundled OnlyOffice x2t converter (cryptpad 2025.9.0) ships with no font data, same failure class as the historical upstream bug cryptpad/cryptpad#1240. Not worth chasing further: CryptPad upstream replaced OnlyOffice entirely with "Euro-Office" in its 2026.10.0 release, and Euro-Office itself lands in nixpkgs with NixOS 26.11 — revisit once nixpkgs bumps the `cryptpad` package to a Euro-Office-based release and re-test import then. Markdown/code/kanban pad types (no OnlyOffice dependency) are unaffected | home VM (`100.64.0.5:3000`) |
| `dokument.vafla.eu` | Cryptpad sandbox domain (iframe origin isolation, required by Cryptpad) — same backend as `dok.vafla.eu`, **no Anubis** (a separate PoW challenge breaks the iframe load — Anubis's challenge page lacks the cross-origin headers CryptPad expects, surfaces as a Firefox `NS_ERROR_DOM_COEP_FAILED`) | home VM (`100.64.0.5:3000`) |
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
| `knigi.vafla.eu` | Calibre — **deployed**. Uses Calibre's own built-in content server (not Calibre-Web), auth via `--enable-auth` (HTTP Basic/Digest — no in-page login form exists in calibre-server, only the OS-native credential popup). Library lives at `/d06-knigi` (dataset root, no subfolder) | home VM (`100.64.0.5:8081`) |
| `muzika.vafla.eu` | Navidrome (server) — clients: Feishin (desktop, native app, not hosted), Wavio (Android, Subsonic API) | home VM |
| `*arr.vafla.eu` | \*arr stack (TBD) | home VM |
| `dns.vafla.eu` | Technitium web UI — **deployed** | home VM (`100.64.0.5:5380`) |
| `headplane.vafla.eu` | Headplane (Headscale web UI) — **deployed** | VPS localhost:3000 |
| `proxmox.vafla.eu` | Proxmox web GUI — **deployed** | Proxmox baremetal (`100.64.0.4:8006`) |
| `prowlarr.vafla.eu` | Prowlarr (indexer manager) — **deployed** | home VM (`100.64.0.5:9696`) |
| `torrent.vafla.eu` | qBittorrent — **deployed**. `WebUI\ReverseProxySupportEnabled`/`TrustedReverseProxiesList` set live (not declared in nix — qBittorrent manages this file itself, a nix-declared `serverConfig` would overwrite runtime password changes on every rebuild). No seeding (can't seed): Seeding Limits → Ratio limit `0` → Pause torrent on reach (not Remove+files — that deletes the download too). Once Radarr/Sonarr exist, use their own "Remove completed downloads" setting instead — only removes the queue entry after the file is confirmed imported into the library | home VM (`100.64.0.5:8090`) |
| `tursi.vafla.eu` | 4get (metasearch, replaces the abandoned SearXNG build) — **deployed**. No nixpkgs package; built from source (`pkgs.fetchgit`) with build-time-patched `config.php`, served via a local nginx+phpfpm pair on the home VM (first local nginx instance in this setup — everywhere else exposes its own HTTP server). Outbound scraping uses `curl-impersonate` (Firefox TLS fingerprint spoofing) | home VM (`100.64.0.5:8098`) |

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
3. `dok.vafla.eu` + `dokument.vafla.eu` (Cryptpad) — tier 0b ✓ deployed
4. `nazhivo.vafla.eu` (Owncast) — tier 0b ✓ deployed
5. `knigi.vafla.eu` (Calibre) — tier 1 ✓ deployed
6. `torrent.vafla.eu` (qBittorrent) — tier 1 ✓ deployed
7. `tursi.vafla.eu` (4get) — tier 1 ✓ deployed
8. `homarr.vafla.eu` (Homarr) — tier 1
9. MC server + `map.mc.vafla.eu` (Bluemap, tier 0b) + `mc.vafla.eu` (static info page, tier 0b)
10. `rechnik.vafla.eu` — tier 0b
11. `git.vafla.eu` (Forgejo) — tier 0b
12. `prowlarr.vafla.eu` (Prowlarr) — tier 1 ✓ deployed. Remaining \*arr stack
    (Radarr/Sonarr/Bazarr, tier 1) + `tv.vafla.eu` (Jellyfin, tier 0b)
13. `tube.vafla.eu` (Peertube) — tier 0b
14. `media.vafla.eu` (Immich) — tier 0b
15. `muzika.vafla.eu` (Navidrome) — tier 1

---

## 12. VPS setup plan

### Domain / service list

**deSEC A records** (all → VPS public IP):

| Record | Tier | Service | When |
|---|---|---|---|
| `vafla.eu` | 0b | MC server :25565 (TCP) + future landing page | Stage 1 |
| `headscale.vafla.eu` | 0a | Headscale control plane | Stage 1 ✓ |
| `bachkali.vafla.eu` | 0b | Gatus | Stage 1 ✓ |
| `mc.vafla.eu` | 0b | Static page | Stage 5 |
| `map.mc.vafla.eu` | 0b | Bluemap | Stage 5 |
| `rechnik.vafla.eu` | 0b | TBD | Stage 5 |
| `taina.vafla.eu` | 0b | Enclosed | Stage 5 ✓ |
| `git.vafla.eu` | 0b | Forgejo | Stage 5 |
| `nazhivo.vafla.eu` | 0b | Owncast | Stage 5 ✓ |
| `dok.vafla.eu` | 0b | Cryptpad | Stage 5 ✓ |
| `dokument.vafla.eu` | 0b | Cryptpad sandbox domain | Stage 5 ✓ |
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
| `torrent.vafla.eu` | 1 | qBittorrent |
| `prowlarr.vafla.eu` | 1 | Prowlarr |
| `tursi.vafla.eu` | 1 | 4get |

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
      VM hardware config (CPU/RAM/disk/BIOS) in `notes/proxmox-baremetal.md`. MC server
      runs as a service inside this VM, not a separate VM.
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

All baremetal/Proxmox-GUI setup (not Nix-reproducible) — host networking, UPS/NUT, ZFS
pool + datasets, Directory Mappings, VirtioFS shares, sanoid snapshot management — moved
to **`notes/proxmox-baremetal.md`**. The NixOS-managed half of Stage 6 (`dns.vafla.eu`/
`proxmox.vafla.eu` Technitium records and nginx vhosts) stays listed in Stage 5 above.

---

## 13. Open items / not yet finalized

### Future idea — Tailscale exit node + VPN layered on top

Not implemented, parked for later. Goal: hide destination traffic (not just DNS, which is
already handled — see §10) from each device's own local network (mobile carrier, café
WiFi) when on the tailnet.

- Exit node candidate: homeserver VM or the VPS (VPS has much better bandwidth — home's
  300Mbps upload becomes the ceiling for *all* traffic through it otherwise, including
  qBittorrent downloads).
- VPN provider: **Mullvad, paid with cash** — runs as a second WireGuard client on the
  exit node; policy routing sends only the phone/laptop's exit-node traffic through it,
  not the VM's own services (SSH, Technitium, etc.).
- Doesn't eliminate destination visibility, just shifts it from the local network to
  Mullvad instead of the home ISP / VPS provider.

### Future idea — ntfy as a central notification hub

Not implemented, parked for later. Self-hosted `ntfy` on homeserver, phone has the ntfy
app subscribed to the relevant topics. Planned senders, all confirmed possible:

- **Disk health** (Scrutiny, see `notes/proxmox-baremetal.md`) — native `shoutrrr` ntfy
  support, for wearout/SMART warnings.
- **Gatus** — native `ntfy` alerting provider (`alerting.ntfy.url`/`topic`/`token`), for
  service-down alerts.
- **Jellyfin** — new-library-item notifications via a dedicated plugin
  (`Jellyfin.Plugin.NtfyNotifier`) or the more general `jellyfin-plugin-webhook`'s ntfy
  integration.
- **Homarr** — Notifications widget reads from ntfy natively, same topic(s) shown on the
  dashboard as well as pushed to the phone.

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
- Seeding a config file into a service's `StateDirectory` when it runs with
  `DynamicUser=true` + `confinement.enable=true` (e.g. Cryptpad): `systemd.tmpfiles.rules`
  silently no-ops ("unsafe path transition" in the journal) because tmpfiles refuses to
  manage a path nested inside a directory it doesn't own. Use
  `systemd.services.<name>.serviceConfig.ExecStartPre` instead (runs as the same
  DynamicUser, inside the same chroot, closure auto-added to the confinement bind list).

Full baremetal/Proxmox-GUI setup detail (UPS/NUT, ZFS pool + datasets, Directory
Mappings, VirtioFS shares, sanoid snapshot management, VM hardware config) lives in
**`notes/proxmox-baremetal.md`** — not Nix-reproducible, kept separate from this doc.

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
