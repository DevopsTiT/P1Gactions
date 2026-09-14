# Placeholder Value Examples

```
Need example values for __…__ tokens?
  │
  ├─ Below = FAKE format examples only
  ├─ Do not copy into production as-is
  └─ Replace with your real SNOW/PD values
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| Purpose | Show **shape** of each value |
| Safe to use as-is? | **No** — examples are fake |
| sys_id look | 32 hex characters |
| PD key look | Usually 32 characters |

## Summary

Use these as a format guide when you Find and Replace. Your real URL, user, password, routing key, and sys_ids must come from your ServiceNow and PagerDuty.

---

## Example values (FAKE — format only)

| Placeholder | Example value | What it should look like |
| --- | --- | --- |
| `__SNOW_INSTANCE_URL__` | `https://acme.service-now.com` | `https://<instance>.service-now.com` — no path, no trailing slash required |
| `__SNOW_USER__` | `dynatrace.workflow` | Login name of the integration user |
| `__SNOW_PASSWORD__` | `Str0ng-Demo-Only-P@ss` | That user’s password (keep secret) |
| `__PD_ROUTING_KEY__` | `R02EXAMPLEKEY000000000000000001` | Events API v2 integration key (~32 chars) |
| `__SNOW_CALLER_SYS_ID__` | `a1b2c3d4e5f6789012345678abcdef01` | 32-char hex from SNOW user record |
| `__SNOW_GROUP_SYS_ID_EIP__` | `b2c3d4e5f6789012345678abcdef0123` | 32-char hex from EIP assignment group |
| `__SNOW_GROUP_SYS_ID_CCI__` | `c3d4e5f6789012345678abcdef012345` | 32-char hex from CCI assignment group |
| `__SNOW_GROUP_SYS_ID_DEFAULT__` | `d4e5f6789012345678abcdef01234567` | 32-char hex from default group |
| `__SNOW_BIZ_SYS_ID_EIP__` | `e5f6789012345678abcdef0123456789` | 32-char hex from EIP business service |
| `__SNOW_BIZ_SYS_ID_CCI__` | `f6789012345678abcdef0123456789ab` | 32-char hex from CCI business service |
| `__SNOW_BIZ_SYS_ID_DEFAULT__` | `789012345678abcdef0123456789abcd` | 32-char hex from default business service |

---

## How it looks after replace (create snippet)

```javascript
const snowBase = "https://acme.service-now.com";
const snowUser = "dynatrace.workflow";
const snowPass = "Str0ng-Demo-Only-P@ss";
const routingKey = "R02EXAMPLEKEY000000000000000001";

callerSysId: "a1b2c3d4e5f6789012345678abcdef01",
groupSysId: "b2c3d4e5f6789012345678abcdef0123",
bizSysId: "e5f6789012345678abcdef0123456789",
```

---

## Also optional (runbook URLs — not `__` tokens)

| Demo value in file | Example real shape |
| --- | --- |
| `https://confluence.example/runbooks/eip` | `https://confluence.mycompany.com/display/OPS/EIP-Runbook` |
| `https://confluence.example/runbooks/cci` | `https://confluence.mycompany.com/display/OPS/CCI-Runbook` |
| `https://confluence.example/runbooks/default` | `https://confluence.mycompany.com/display/OPS/Default-Runbook` |

---

## Quick format checks

| Value type | Pass if |
| --- | --- |
| Instance URL | Starts with `https://` and ends with `.service-now.com` (or your host) |
| User | No spaces; real login that can create incidents |
| Password | Whatever SNOW requires; never leave `__SNOW_PASSWORD__` |
| PD key | Long alphanumeric string from PD Integrations page |
| Any sys_id | Length 32, hex chars `0-9` `a-f` only (typical) |

---

## Data flow map

```
Example table (format)
  → you substitute YOUR real values
  → Find/Replace into YAML/JSON
  → upload
```

## Related files

| Path | Why |
| --- | --- |
| `../20-how-to-replace-placeholders/` | How to do Find/Replace |
| `../19-replace-placeholders-exact/` | Exact token list |
| `21.sh` | Reminders |

## Commands

See `21.sh` in this folder.
