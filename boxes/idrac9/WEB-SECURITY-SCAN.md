# iDRAC9 Web Interface — Static Security Scan

Static analysis of the exposed web surface in extracted iDRAC9 firmware. No live
testing was performed; every finding is grounded in a file:line in the rootfs.

- ROOTFS: `/Users/zen/phd/bmc/idrac9-firmware/extracted/rootfs`
- Web roots: `…/usr/local/www/{restgui,rfservice,scvservice,software,help,debranded,bmcbranded}`
- Apache config (factory copy, deployed to `/etc/apache2`): `…/usr/share/factory/etc/apache2/`
- GUI = AngularJS 1.x SPA in `restgui/` (gzipped `*.js.gz` / `*.html.gz`); vConsole/vMedia
  = separate Angular(modern)+webpack bundles in `restgui/vconsole/` and `restgui/vmedia/`.
- Decompressed working copy: `…/scratchpad/webscan/`

Apache paths below are relative to `usr/share/factory/etc/apache2/conf.d/` unless noted.

---

## 1. Exposed surface map (endpoint → auth → handler)

Auth model: a FastCGI **Authorizer** (`fcgi-auth` @127.0.0.1:4300) is wired as an
Apache `AuthnzFcgiCheckAuthnProvider` over selected `LocationMatch` blocks. Where a
block sets `IS_AUTHNZ_REQUIRED=0` or `SetEnvIf Authorization ^$ IS_AUTHNZ_REQUIRED=0`,
the request is passed to the backend *without* an Apache auth gate (backend may still
re-check). HTTP (:80) is redirect-only to HTTPS for GET/HEAD; non-GET → 404; OPTIONS → 405;
`/cgi-bin` over HTTP → 404 (`03-vhosts.conf:34-81`).

| Endpoint (prefix) | Auth required? | Handler / backend | Evidence |
|---|---|---|---|
| `/restgui/*` (GUI SPA static) | **No** for assets; `.html` runs MUT handler | Apache static + `mut-handler`; `.gz` variants auto-served | `httpd_gui.conf:20-84`, `fcgi-auth-mut.conf:12` |
| `/restgui/` (bare dir) | n/a — **403 forbidden** | — | `03-vhosts.conf:80-81,206-207` |
| `/sysmgmt/*` (ReST GUI API) | **Yes** (fcgi-auth, session) | proxy → `fcgirds.socket` | `fcgi-auth.conf:51-60`, `03-vhosts.conf:87-91` |
| `/sysmgmt/2015/bmc/info` (GET) | **No (authnz bypassed)** | fcgirds | `httpd_gui.conf:11-13` |
| `/sysmgmt/2016/bmc/language` (GET) | **No (authnz bypassed)** | fcgirds | `httpd_gui.conf:11-13` |
| `/sysmgmt/2012/server/configgroup/iDRAC.userdomain` (GET) | **No (authnz bypassed)** | fcgirds | `httpd_gui.conf:11-13` |
| `/sysmgmt/2015/bmc/session` (POST, no query) | **Yes** (Basic, fcgi-auth) — login | fcgirds | `fcgi-auth.conf:76-88` |
| `/sysmgmt/2015/bmc/session` (POST `?authtype=tfa`) | client cert (`SSLVerifyClient optional_no_ca`) | backend | `03-vhosts.conf:233-238` |
| `/redfish`, `/redfish/v1` (root) | **No** when no `Authorization` hdr | static JSON alias | `httpd_redfish.conf:222-228` |
| `/redfish/v1/{Registries,JSON/JsonSchemas,Schemas,odata,$metadata,openapi.yaml}` | **No** when no `Authorization` hdr | static aliases | `httpd_redfish.conf:236-262,499` |
| `/redfish/v1/Managers/(1\|iDRAC.Embedded.1)/PrivilegeRegistry` | **No** when no `Authorization` hdr | static alias | `httpd_redfish.conf:256-258,651` |
| `/redfish/*` (everything else) | **Yes** (Basic + session) | fcgi RF responders @4200-4204 | `fcgi-auth.conf:104-130`, `httpd_redfish.conf:150-164` |
| `/redfish/v1/Downloads/<x>` | **Yes** | static file `/mmc1/pel/<x>` | `httpd_redfish.conf:696` |
| `/redfish/v1/Dell/*.{xml,csv,gz,zip,txt,csr,pem,crt,log,svgz}` | **Yes** | static aliases to `/var/run/wsman/...` | `httpd_redfish.conf:656-696` |
| `/wsman` | **Yes** (Basic, fcgi-auth) | `wsman-handler` (libmodwsman.so) | `fcgi-auth.conf:24-46`, `idrac-wsman.conf:4` |
| `/cgi-bin/(exec\|putfile\|logout)` | **Yes** (fcgi-auth) | ScriptAlias `/usr/local/cgi-bin/` | `fcgi-auth.conf:51`, `httpd_rracadm.conf:6` |
| `/cgi-bin/login` (POST) | **No Apache gate** (login is pre-auth) | proxy → `fcgiracadm.socket` | `httpd_rracadm.conf:32-36`, `fcgi-auth.conf:51` |
| `/cgi-bin/discover?MODE=PROXY` (GET) | **No Apache gate** | proxy → `fcgiracadm.socket` | `httpd_rracadm.conf:23-30` |
| `/dtapi`, `/api`, `/idrac/plugins` | **Yes** (Basic, `SSLRequireSSL`) | proxy → `telemetryservice/http.socket` | `fcgi-auth.conf:62-74`, `03-vhosts.conf:102-107` |
| `/baseboardservice/(HMC\|SMC).Embedded.1/*` | **Yes** (Basic) except bare redfish root | backend | `fcgi-auth.conf:90-102`, `httpd_redfish.conf:230-234` |
| `/oauth/token` (POST) | n/a (token endpoint, `SSLRequireSSL`) | proxy → fcgi @4400 | `fcgiresponder.conf:7-25` |
| `/register`,`/authorize`,`/cb`,`/ssh_cert`,`/token_test` | n/a (OAuth/OIDC flow) | proxy → fcgi @4400 | `fcgiresponder.conf:1-5` |
| `/oauth_discovery/*` | **No — `Require all granted`** | static dir `/var/run/oauth_discovery/` | `fcgiresponder.conf:31-36` |
| `/protected/*` | **Yes** (`AuthType openid-connect`, valid-user) | proxy → fcgirds | `auth_openidc.conf.orig:7-19` |
| `/vkvm/` (ws) | backend token | `ProxyPass ws://127.0.0.1:5900` | `01-idrac-vconsole.conf:8` |
| `/vnc/vconsole` (ws upgrade) | backend token | `ws://127.0.0.1:5905` | `03-vhosts.conf:121-124` |
| `/vnc/vmedia` (ws upgrade) | backend token | `ws://127.0.0.1:5951` | `03-vhosts.conf:126-129` |
| `/console` (+`?username&tempUsername&tempPassword`) | redirect → vconsole (MSM SSO) | rewrite | `03-vhosts.conf:142-147` |
| `/capconsole`,`/capdata`,`/bootcapture`,`/crashcapture` | **Yes** (fcgi-auth) | static aliases `/var/run/...` | `fcgi-auth.conf:51`, `httpd_gui.conf:118-127` |
| `/gmdwn/*`, `/Applications/*` (GM/CMC SSO) | **Yes** (fcgi-auth) | static / proxy | `fcgi-auth.conf:51`, `httpd_gui.conf:129` |
| `/dtapi/rest/v1/.../openapi.yaml` | **No** (served static, proxy bypass) | Alias `scvservice/Schemas/openapi.yaml` | `03-vhosts.conf:98-99` |
| `/.well-known/acme-challenge` | **No** | `/var/run/apache2` | `03-vhosts.conf:100` |
| `/index.html` | **No** | Alias `/etc/websockets/index.html`, `Require all granted` | `03-vhosts.conf:224-229` |

---

## 2. Findings ranked by severity

### HIGH

**H1 — Stored/DOM XSS: Lifecycle-Controller log / work-note `message` rendered as trusted HTML without escaping.**
The dashboard and storage LC-log grids bind the server-supplied `message` field via
`ng-bind-html` after wrapping it in `$sce.trustAsHtml()` with **no HTML escaping**:
- `js/controllers/dashboard/dashboardcontroller.js:177` cellTemplate `<span ng-bind-html = row[column.map]>`, fed at `:196` `lcldata[key].message = $sce.trustAsHtml(lcldata[key].message);`
- `js/controllers/storage/storageinfocontroller.js:359` same cellTemplate, fed at `:444` `lcldata[key].message = $sce.trustAsHtml(lcldata[key].message);`

Why it matters: the same codebase escapes elsewhere —
`js/controllers/system/detailedinfocontroller.js:685` does
`$sce.trustAsHtml(commonutility.escapeHtml(attributes[attr]))`, and
`js/controllers/groupmanager/groupmanager.js:623` wraps every field in
`commonutility.escapeHtml(...)`. The dashboard/storage paths omit that step, so any
HTML/JS that reaches an LC-log `message` renders in an authenticated admin's browser.
The dashboard grid exposes an `add_note` action (`dashboardcontroller.js:181`), i.e.
work-note text is user-supplied and flows back into this field → classic stored XSS.
This mirrors the previously-documented iDRAC6 stored-XSS-via-logged-string pattern.
**Caveat (unverified):** needs a live target to confirm (a) the backend does not
sanitize work-note / LC-log text server-side, and (b) the note text reaches this exact
`message` field unescaped. Promote to confirmed only after that test.

### MEDIUM

**M1 — Session auth token transported in URL query string (leak + fixation surface).**
`js/controllers/logincontroller.js`:
- `:132-134` reads `xsrf-token` **from the URL query string** (`getUrlVars()['xsrf-token']`) and stores it in `XSRF_TOKEN`.
- `:520` uses that value as the Redfish **`X-AUTH-TOKEN`** header (`redfish_headers`), and `:274,:519` as the `XSRF-TOKEN` header — i.e. it is the live session credential, not a mere anti-CSRF nonce.
- `:749,:753,:755` write it back into navigations: `window.location.replace("index.html?"+XSRF_TOKEN+"&vconsole")`, `igm.html?"+XSRF_TOKEN`.

Why it matters: auth tokens in the URL leak through browser history, the `Referer`
header to any third-party asset, and any intermediary/access logs. Accepting the token
from an attacker-influenceable URL is also a token-fixation foothold. This is the
SSO/vConsole post-auth handoff path (`authResult==7`). **Caveat:** token lifetime/binding
is enforced server-side and unverified here; severity depends on whether the token is
single-use / IP-bound.

**M2 — Unauthenticated information disclosure on three `/sysmgmt` GETs.**
`httpd_gui.conf:11-13` sets `IS_AUTHNZ_REQUIRED=0` for GET on
`/sysmgmt/2015/bmc/info`, `/sysmgmt/2016/bmc/language`, and
`/sysmgmt/2012/server/configgroup/iDRAC.userdomain`. The login SPA consumes `UserDomain`
pre-auth to populate the AD-domain dropdown (`logincontroller.js:139-160`), so configured
Active Directory domain names are readable without credentials; `bmc/info` yields model /
generation / firmware data useful for fingerprinting and version-specific exploit
selection. Low-sensitivity individually, but unauthenticated.

**M3 — Legacy MSM SSO passes credentials in the URL query string.**
`03-vhosts.conf:142-147`: `/console?username=…&tempUsername=…&tempPassword=…` is matched
and redirected to the vConsole URI. A `tempPassword` (and usernames) in a GET query string
lands in proxy logs, history and `Referer`. Marked "Assume MSM triggers this only over
HTTPS" in-config — TLS hides it on the wire but not from logs/history.

**M4 — CSP permits `'unsafe-inline'` in `script-src`.**
`httpd_gui.conf:88`:
`Content-Security-Policy "default-src 'self'; … script-src 'self' 'unsafe-inline'; …
style-src 'self' 'unsafe-inline'; … object-src 'none';"`.
`'unsafe-inline'` in `script-src` removes CSP's protection against injected inline
scripts/event-handlers — exactly the class of payload H1 would deliver. `object-src 'none'`,
`default-src 'self'`, and the absence of `unsafe-eval` are good; the inline-script allowance
is the weak point. (Positive: `connect-src` restricted to `'self' wss:`.)

### LOW / informational

**L1 — `OIDCCryptoPassphrase calvin` is a template default, not a live secret.**
`auth_openidc.conf.orig:5` ships the literal `calvin`, but this is a `.orig` **template**:
`etc/sysapps_script/base_httpd.sh:125-128` (`create_oidc_crypto_passphrase`) overwrites it
with a random 16-byte `/dev/urandom` value, and only when an SSO metadata dir exists
(`base_httpd.sh:653-658`); otherwise the conf is moved back to `.orig` and not loaded. So
`calvin` is not the operational passphrase. Informational only — flagged because the literal
is eye-catching and would be a real fleet-shared secret if the regeneration step ever fails.

**L2 — `/redfish/v1/Downloads/(.*)` → static file `/mmc1/pel/$1` (unanchored capture).**
`httpd_redfish.conf:696` `AliasMatch ^/redfish/v1/Downloads/(.*)/?$ "/mmc1/pel/$1"`. The
`(.*)` is unanchored; path traversal is normally neutralised by Apache request-path
normalisation (it collapses `..`), and the path is auth-gated, but the raw filesystem map of
attacker-influenced suffix into `/mmc1/pel/` warrants a focused traversal/symlink test.

**L3 — vConsole/vMedia WebSocket proxies have no Apache auth gate.**
`/vkvm/`→5900 (`01-idrac-vconsole.conf:8`), `/vnc/vconsole`→5905, `/vnc/vmedia`→5951
(`03-vhosts.conf:121-129`) are reverse-proxied with only `Upgrade: websocket` conditions;
no `fcgi-auth` `LocationMatch` covers them. Authentication is delegated to the KVM/vMedia
backend's own token (the URL-borne token of M1). Lead for the binary RE side.

**L4 — `/cgi-bin/login` and `/cgi-bin/discover?MODE=PROXY` are not in the fcgi-auth set.**
`fcgi-auth.conf:51` only auth-gates `cgi-bin/(exec|putfile|logout)`. `login` is pre-auth by
nature; `discover?MODE=PROXY` (remote-RACADM/MSM discovery) reaches `fcgiracadm.socket`
unauthenticated at the Apache layer and relies entirely on the remoteracadm backend to
authorise. Worth confirming the backend's check.

**L5 — `Require all granted` static dirs.** `/oauth_discovery/` (`fcgiresponder.conf:34-36`),
`/usr/local/www` docroot (`03-vhosts.conf:213-217`), `/etc/websockets` (`:225-229`),
`/usr/local/cgi-bin` (`httpd_rracadm.conf:9-13`), `/var/lib/remoteracadm`
(`httpd_rracadm.conf:44-48`). All serve intentionally-public or self-protecting content, but
each is an unauthenticated read surface to inventory.

**Positive controls observed (no action):** `TraceEnable off` (`httpd_tuning.conf:20`);
`ServerTokens ProductOnly` + `ServerSignature Off` in the active `httpd.conf:522-523` (the
`Full` token in `extra/httpd-default.conf:55` is **not** Included — `httpd.conf:482`);
HSTS `max-age=31536000; includeSubDomains; preload` (`03-vhosts.conf:178`);
`X-Frame-Options DENY` global (`httpd_tuning.conf:51`) + `SAMEORIGIN` on GUI
(`httpd_gui.conf:90`); `X-Content-Type-Options nosniff` (`httpd_gui.conf:89`);
`Proxy` header unset early — CVE-2016-5387 httpoxy mitigation (`httpd_tuning.conf:65`);
TLS forced to 1.2 with an AEAD-only, no-DH/no-kRSA cipher list (`00-base.conf:18-21`);
HTTP/2 module shipped disabled (`h2.conf.disabled`); no app source maps shipped (only
vendored `angular.min.js` reference non-present `.map`s); no hardcoded secrets/tokens found
in the `vconsole`/`vmedia` webpack bundles or app controllers; no `postMessage`/message
listeners and no `eval`/`document.write` in app (non-vendored) JS.

---

## 3. Notable observations / leads for deeper RE

1. **Auth and method enforcement live almost entirely in Apache rewrite regex.**
   `httpd_redfish.conf` alone carries hundreds of `RewriteCond`/`RewriteRule` lines, including
   the unauthenticated-exclusion gates built from long negative-lookahead regexes
   (`httpd_redfish.conf:150-164,236,499`). A single regex edge case (alternate encoding,
   trailing-slash/`;`-param, case, `//` collapse) can flip a route between the
   "auth-required" and "served-static / `IS_AUTHNZ_REQUIRED=0`" branches. This is the
   highest-value fuzzing target on the perimeter: enumerate inputs that satisfy a
   `SetEnvIf Authorization ^$` / `IS_AUTHNZ_REQUIRED=0` block while still reaching a
   privileged backend handler.

2. **`IS_AUTHNZ_REQUIRED=0` is an Apache-layer *hint*, not a decision.** Several blocks
   relax the Apache gate and explicitly defer to the Authorizer/RDS backend
   (`fcgi-auth.conf:104-115` comment; `httpd_gui.conf:8-13`). The real authorization for
   those routes lives in the `fcgi-auth` binary (@4300) and the RDS responder — out of scope
   for static web analysis, but the place to confirm M2/L4 actually re-check.

3. **Token-in-URL pattern (M1) recurs across the SSO/GM/vConsole handoff.** `logincontroller.js`
   moves `XSRF_TOKEN`/`X-AUTH-TOKEN` through `index.html?`, `igm.html?`, and the
   `/console?...&vconsole` flow. Tracing how the backend mints, scopes and expires this token
   (single-use? IP/session-bound?) determines whether M1 is a leak nuisance or a session-hijack
   primitive. Pairs with the documented URL-borne `tempPassword` MSM path (M3).

4. **LC-log / work-note rendering inconsistency (H1) suggests a class bug.** Grep the full
   controller set for every `ng-bind-html` + `trustAsHtml` pair and classify each as
   escaped (`escapeHtml` applied) vs raw. Confirmed raw so far: dashboard, storage. Confirmed
   escaped: detailedinfo, groupmanager. The `tooltipmsg`/`TooltipMesg` family
   (`commonutility.js:1890-1943`, `users.js`, `groupmanager.js`) should be audited for whether
   the tooltip strings ever carry server/user data vs static localised templates.

5. **`oidcErrorTemplate.html` auto-POSTs `error`/`description` into `start.html`.**
   `usr/local/www/restgui/oidcErrorTemplate.html` is
   `<form action="/restgui/start.html?error=%s&description=%s"> ... onload submit`. The `%s`
   are filled by mod_auth_openidc. `logincontroller.js:118-128` reads `error` and compares it
   to fixed codes (`SYS525`), emitting only translated static strings — so no reflected XSS via
   `error` in the paths reviewed. Confirm `description` is never reflected into the DOM by
   `start.html`/its controller before clearing this lead.

6. **vConsole/vMedia are modern-Angular webpack bundles** (`restgui/vconsole/`, `restgui/vmedia/`,
   plus `restgui/vconsole.gz` single-file bundle) distinct from the AngularJS 1.x GUI. They were
   scanned for literal secrets (none found) but not deeply reviewed; the KVM/vMedia client +
   its WebSocket token handling (L3, M1) is a separate audit surface.
