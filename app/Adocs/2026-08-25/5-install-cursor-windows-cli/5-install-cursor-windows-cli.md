# Install Cursor With Windows CLI

```
Want Cursor via CLI on Windows?
  |
  Read seq 4 first (AD / policy basics)
    → Daily Files/2026-08-25/4-install-cursor-ad-windows/
  |
  Network allow to cursor.com / winget sources?
    No  → stop; ask IT for allowlist (do not bypass)
    Yes → continue
  |
  AppLocker / WDAC / AV blocks unknown EXE?
    Yes → CLI will fail too; use Software Center / IT ticket (seq 4 Path C/D)
    No  → try CLI
  |
  Have winget?
    Yes → prefer: winget install --id Anysphere.Cursor --exact
         Prefer --scope user if no admin
    No  → check org Chocolatey, or download + silent Inno flags
  |
  Still blocked?
    → Do not bypass. Follow seq 4 Path C/D
```

## Short takeaway

| Key point | Detail |
|-----------|--------|
| Short answer | Yes, you can try Windows CLI (winget first). AD policy may still block it. |
| Primary command | `winget install --id Anysphere.Cursor --exact` |
| Package ID | Confirmed: **Anysphere.Cursor** (Microsoft winget-pkgs / WinGet catalogs) |
| Policy reality | CLI still needs network allow. AppLocker can block the same installer the GUI uses. |
| No admin | Prefer **user-scope** install. Machine scope often needs elevation. |
| Do not bypass | No AppLocker workarounds, no unsigned sideloading tricks. Use IT channels. |

## Summary

CLI does not skip company controls. Winget, Chocolatey, Scoop, or a silent EXE all download and run an installer. On an AD/Intune PC, use the same judgment as the [AD Windows guide (seq 4)](../4-install-cursor-ad-windows/4-install-cursor-ad-windows.md): try user-scope when allowed; if policy blocks, request an approved deploy.

**Commands below are for Windows PowerShell or cmd on the target PC.** Do not run them from a Mac agent.

## What each CLI option is

| Option | What it is | Why you care |
|--------|------------|--------------|
| winget | Windows Package Manager (built into modern Windows 10/11) | Best first try; official package ID **Anysphere.Cursor** |
| Chocolatey | Popular third-party Windows package manager | Only if your org already installs and allows `choco` |
| Scoop | User-folder package manager | Rare on AD PCs; often community buckets only |
| Direct EXE + silent flags | Download Cursor’s Inno Setup installer and run quiet switches | Useful when winget is missing but downloads are allowed |
| Invoke-WebRequest | PowerShell download helper | Gets the installer file; you still run it (and policy still applies) |

## 1. winget (preferred)

**What this is:** Microsoft’s built-in app installer. **Why it matters:** one known package ID, easy to search and install.

Search then install (exact ID confirmed):

```text
winget search Cursor
winget install --id Anysphere.Cursor --exact
```

Prefer user scope when you lack admin:

```text
winget install --id Anysphere.Cursor --exact --scope user
```

Quiet-ish automation (still subject to policy):

```text
winget install --id Anysphere.Cursor --exact --silent --accept-package-agreements --accept-source-agreements
```

| Flag / idea | What it means | When to use |
|-------------|---------------|-------------|
| `--id Anysphere.Cursor` | Exact package identity | Always prefer this over a fuzzy name |
| `--exact` | Do not fuzzy-match other apps | Safer on shared PCs |
| `--scope user` | Install for your account | No local admin / locked laptop |
| Machine scope (default in some setups) | Often needs admin | Only if IT allows system-wide apps |
| `--silent` + accept agreements | Less interactive | Scripts / repeat installs |

**Happy path:** winget finds the package → downloads → Inno installer runs → Cursor opens from Start Menu.

**Common mistake:** assuming winget bypasses AppLocker. It does not.

## 2. Chocolatey (if org already has it)

Community package id is commonly **`cursoride`** ([chocolatey.org/packages/cursoride](https://community.chocolatey.org/packages/cursoride)). Default tends toward **user** install; `/System` is a package parameter for machine-wide.

```text
choco install cursoride -y
```

Only use Chocolatey if IT already provides it. Do not install Chocolatey yourself just to dodge policy.

## 3. Scoop (less common on AD)

Scoop is usually per-user under your profile. Cursor is not a standard main-bucket app on most corp images; community buckets exist but are a weak fit for AD.

Prefer winget or IT-approved catalog instead.

## 4. Direct download + silent Inno flags

Cursor’s Windows installer is **Inno Setup**. Reported quiet switches:

```text
CursorUserSetup-x64-<version>.exe /VERYSILENT /SUPPRESSMSGBOXES /NORESTART
```

| Switch | What it means |
|--------|---------------|
| `/VERYSILENT` | No wizard UI |
| `/SUPPRESSMSGBOXES` | Suppress message boxes |
| `/NORESTART` | Do not reboot |

Prefer the **User** setup EXE when you have no admin (same idea as seq 4). Download only from [https://cursor.com/download](https://cursor.com/download).

## 5. PowerShell download then start installer

Example pattern (adjust URL/filename to the official User installer you downloaded from cursor.com):

```text
Invoke-WebRequest -Uri "https://downloader.cursor.sh/..." -OutFile "$env:TEMP\CursorUserSetup.exe"
Start-Process -FilePath "$env:TEMP\CursorUserSetup.exe" -ArgumentList "/VERYSILENT","/SUPPRESSMSGBOXES","/NORESTART" -Wait
```

Replace the URI with the current official download link. Blind URLs go stale; when unsure, download from the website once, then reuse that file path.

## AD / policy checklist (CLI does not skip this)

| Check | What it means | Why you care |
|-------|---------------|--------------|
| Network allow | PC can reach winget CDN and Cursor download hosts | CLI fails with timeout / 403 if blocked |
| AppLocker / WDAC | Only approved EXEs may run | Installer blocked = winget/choco blocked too |
| User vs machine scope | User → profile folder; machine → Program Files | No admin → stick to user scope |
| Software Center | Company approved catalog | Prefer this if Cursor is listed |
| Do not bypass | No policy disable tricks | Security and employment risk |

## Happy path vs common mistakes

| Path | What happens |
|------|--------------|
| Happy | `winget install --id Anysphere.Cursor --exact --scope user` → install under `%LOCALAPPDATA%` → sign in |
| Mistake | Force machine scope without admin → UAC / access denied |
| Mistake | Treat CLI as a bypass for AppLocker → same block, wasted time |
| Mistake | Install Scoop/Chocolatey without approval → new policy problem |
| Next step if blocked | Seq 4 Path C/D: Company Portal or IT ticket |

## Data flow map

```
You (Windows PowerShell/cmd)
  → winget / choco / Scoop / Invoke-WebRequest
      → download Cursor Inno installer (needs network allow)
          → run EXE (AppLocker may allow or deny)
              → User scope → %LOCALAPPDATA%\Programs\cursor\
              → Machine scope → Program Files (admin)
                  → Cursor app → sign in → AI features (proxy/SSL if corp network)
```

## Related files

| File | Role |
|------|------|
| [5-install-cursor-windows-cli.md](./5-install-cursor-windows-cli.md) | This guide |
| [5.sh](./5.sh) | Windows one-liners (run on the Windows PC) |
| [../4-install-cursor-ad-windows/4-install-cursor-ad-windows.md](../4-install-cursor-ad-windows/4-install-cursor-ad-windows.md) | AD / policy install paths |
| CursorFiles | `/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-08-25/5-install-cursor-windows-cli/` |

## Commands

All one-liners live in [5.sh](./5.sh). **Run them on Windows**, not on macOS.

Primary install:

```text
winget install --id Anysphere.Cursor --exact
```
