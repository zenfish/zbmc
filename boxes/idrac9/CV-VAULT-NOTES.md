# iDRAC9 Credential Vault (CV) — what's actually in it

**Date:** 2026-06-25. Enumerated live on the virtual iDRAC9 (Phase-4 VM, factory-default state).
Companion to `RAKP-USER-INVESTIGATION.md` (the CV was the store that broke our UserName path —
DBLocation=3 lives here). This note = what the vault holds and why it matters.

## What the CV is
The **Credential Vault** is iDRAC9's single at-rest secret store: a dm-crypt volume mounted at
**`/mnt/cv`** (symlinked from `/flash/data0/cv`), set up by `/etc/init.d/credential-vault.sh`.
Every daemon that owns a secret gets a subdir under it. cfgdb's secret-class attributes
(metadata `DBLocation=3` — passwords, passphrases) live in `/mnt/cv/cfgdb/CfgCurrentValues.db`.

**The crypto that protects it is decorative against anyone with the firmware:** the dm-crypt key
is hardcoded and **fleet-shared** —
`00d078507dc33c9c669669be8a8dda51f3dce8d0205ab0e6802c3d9cfe683a6d` (AES-256), sitting in the
world-readable `credential-vault.sh`. One key decrypts the vault on *every* iDRAC9.
(See memory `reference_idrac9_cv_aes_key`.) So "the secrets are encrypted" buys nothing against
an attacker who has read any iDRAC9 firmware image — which is public.

## What's in the vault (live enumeration, factory state)
One subdir per secret domain — the vault is pre-provisioned for ALL of these even on a fresh box;
most are empty until the corresponding feature is configured:

| Path | Owner | Holds | Factory state |
|------|-------|-------|---------------|
| `avctpasswd` | login/IPMI | root + 16 user records: PBKDF2 pw hash, **IPMIKey** (RAKP), salt | POPULATED (root present) |
| `cfgdb/CfgCurrentValues.db` | cfgdb | all 16 users' `Password`, `SNMPv3AuthenticationPassphrase`, `SNMPv3PrivacyPassphrase`; `SecureDefaultPassword` AES key+IV | POPULATED |
| `sekmkeydir` | — | **SEKM** (Secure Enterprise Key Manager) — the iDRAC's **KMIP client credential** (TLS client cert + private key enrolled with the external KMS, + KMS CA). NOT the drive keys themselves — see correction below. | empty (no SEKM configured) |
| `krb_keytab` | datamgr | Kerberos keytab = iDRAC's **AD machine-account creds** when domain-joined | 0 bytes (no AD join) |
| `oauth`, `mod_auth_openidc` | oauthd | OAuth/OIDC client secrets + keys | empty |
| `snmpd` | snmp | SNMPv3 engine secrets | empty |
| `supportassist` | supporta | SupportAssist creds (phones home to Dell) | empty |
| `BNR` | wsman | backup-and-restore secret material | empty |
| `rm` (recman), `private`, `power`, `apphandler`, `libxmlsupport`, `sekmkeydir` | various | per-daemon secrets | empty |

### The two interesting always-present secrets
1. **`SecureDefaultPassword.AESKey` = `F91BF6F12B09E262DD1A140D6B0446F7`** (AES-128) + **AESiv
   `1F80BEE33234692AED2164407F76E1C3`** — a key stored *inside* the vault. This protects the
   "secure default password" feature (the per-unit factory default password Dell uses instead of
   calvin on newer units). Note: these values came from our synthetic metadata-DEFAULT build, so
   on real hardware this key MAY be per-unit-random rather than fleet-shared — **UNCONFIRMED, worth
   checking against a real unit's CV.** If it's a metadata default (fleet-shared), the per-unit
   "secure default password" is recoverable once you have the CV key.
2. **`avctpasswd` root record** — `root:yhmydQG7Dr4U7kBKO+5QDI1Jt/747mBlyF//F0lZBx0=:2:1:Administrator:…`
   field2 = PBKDF2 password hash, field14 = the RAKP **IPMIKey** `915F32…8964`, field15 = salt.
   This is the credential the whole RAKP work hinges on.

## Why it matters (threat model)
The vault's security assumes its key is secret/per-unit. It isn't — it's one hardcoded fleet key.
So a single firmware-derived key is the master key to **every** at-rest secret on **every**
iDRAC9, and the vault is the umbrella over secret classes that reach far past the BMC:

- **Drive data (CORRECTED — narrower than first written):** SEKM keeps the actual encryption keys
  on an **external KMIP key management server (KMS)**, not on the iDRAC. The iDRAC is a KMIP
  *client*: at boot it mutual-TLS-authenticates to the KMS, fetches the key transiently, and hands
  it to PERC to unlock the SEDs — it does not persist media keys at rest. So `sekmkeydir` holds the
  iDRAC's **KMIP client cert + private key** (its identity to the KMS), not the drive-unlock keys.
  Impact of CV compromise: an attacker recovers THAT unit's KMIP client identity and could
  **impersonate the iDRAC to the KMS to request its drive keys** — conditional on KMS reachability
  and policy, and **per-unit** (the client cert is enrolled per-iDRAC), NOT fleet-wide like the CV
  AES key. Still a BMC-vault → host-drive-data path, but via KMS impersonation, not local key theft.
  CONFIRMED by Dell's own doc — iDRAC9 Security Configuration Guide (2022-06 Rev A01, Ch11 p33;
  filed `~/phd/dox/references/dell-idrac9-security-configuration-guide-2022-06-revA01.pdf`,
  artifact `2505d88a-2a64-5bc3-b060-d932905ab643`): *"iDRAC requests the KMS to create a key for
  each storage controller, and then fetches and provides that key to the storage controller on
  every host boot… Because the keys used to lock and unlock the SEDs are not stored on the server,
  attackers cannot access data even if they steal a server."* iDRAC holds only a TLS/SSL KMIP
  client cert (CN/UID/OU maps to the KMS user owning the keys). Exact `sekmkeydir` contents on a
  SEKM-enrolled unit = still TO VERIFY on real HW (factory VM has it empty).
- **Active Directory foothold:** `krb_keytab` = the iDRAC's domain machine-account keytab on an
  AD-joined box → authenticate as the machine account into the domain.
- **Identity/SSO:** `oauth`/`mod_auth_openidc` client secrets.
- **All local + IPMI creds:** every user's password hash, IPMIKey, and SNMPv3 passphrases.
- **Phone-home:** SupportAssist creds.

**The point:** the CV "encryption everywhere" is not a second line of defense — it's one
fleet-shared key gating a pile of high-value secrets, several of which (drive keys, AD keytab)
are NOT BMC-local. This is a separate problem from the calvin default password and from the RAKP
hash-disclosure oracle (CVE-2013-4786): fixing those does nothing about the CV key.

## Open / to verify on real hardware
- Is `SecureDefaultPassword.AESKey` fleet-shared (metadata default) or per-unit-random? (Decides
  whether the per-unit secure default password is fleet-recoverable.)
- Populate `sekmkeydir` on a SEKM-configured box and confirm the SED unlock keys decrypt under the
  fleet CV key.
- `krb_keytab` on a domain-joined unit → confirm machine-account auth.

## Provenance
Live VM: `/mnt/cv` on the Phase-4 virtual iDRAC9 (`./run-p4.sh`). Firmware:
`~/phd/bmc/idrac9-firmware`. Related memories: `reference_idrac9_cv_aes_key`,
`reference_idrac9_factory_ipmikey`, `reference_idrac9_more_fleet_secrets`,
`reference_idrac9_user_table_storage`, `reference_bmc_auth_architecture`.
