# Install Cursor On AD Windows

```
Need Cursor on company Windows PC?
  |
  Is the PC domain-joined / Intune-managed?
    No  → normal home install (User installer is fine)
    Yes → continue
  |
  Can you install apps yourself (local admin)?
    Yes → Path A: download System or User installer → Run as admin if prompted
    No  → try Path B first
  |
  Path B: User (per-user) installer from cursor.com/download
    Installs under %LOCALAPPDATA%\Programs\cursor\
    Works? → sign in → done
    Blocked (AppLocker / SmartScreen / AV / GPO)? → do NOT bypass
  |
  Company has Software Center / Company Portal?
    Yes → Path C: request Cursor as approved app
    No / not listed → Path D: IT ticket
  |
  Path D ticket asks for:
    exception, AppLocker allow rule, or Intune/MDM package deploy
  |
  After install: sign in → optional VS Code import → if AI fails, check proxy/SSL with IT
```

## Short takeaway

| Key point | Detail |
|-----------|--------|
| What “AD controlled” means | The PC is joined to company Active Directory (or managed by Intune). Group Policy, AppLocker, and antivirus can block unknown installers. |
| Best first try without admin | Cursor **User installer** (per-user). It goes under your profile, not `Program Files`. |
| If that is blocked | Stop. Use Software Center / Company Portal, or open an IT ticket. Do not bypass security. |
| Official download | [https://cursor.com/download](https://cursor.com/download) — pick Windows, then User or System. |

## Summary

On a company-managed Windows PC, “install Cursor” is often a **policy** question, not only a download question. Cursor ships two Windows installers: **User** (no admin, under `%LOCALAPPDATA%`) and **System** (admin, under `Program Files`). Try User first if you lack admin; if policy blocks it, request Cursor through IT channels instead of fighting the controls.

## What “AD controlled” means

| Term | What it means | Why you care |
|------|---------------|--------------|
| Active Directory (AD) | Company directory of users and PCs | Your login and device follow company rules |
| Domain-joined | PC is a member of that company domain | Policies can apply at logon and on a schedule |
| Group Policy (GPO) | Central settings pushed to PCs | Can block unsigned apps, force software sources, restrict downloads |
| Intune / MDM | Cloud device management (common with Microsoft 365) | Same idea: company can allow or deny installs |
| AppLocker / WDAC | Rules for which `.exe` files may run | Cursor’s installer may be blocked until IT allows it |
| Software Center / Company Portal | Company app store for approved software | Often the **only** legal way to install tools at work |

**Plain English:** the PC is not fully yours. Security may require admin rights, force installs only from IT’s catalog, or block unknown executables. That is normal for work devices.

## Normal Cursor Windows install (home or unlocked PC)

1. Open [https://cursor.com/download](https://cursor.com/download).
2. Choose **Windows**.
3. Pick an installer:
   - **User installer** — installs for your account only under `%LOCALAPPDATA%\Programs\cursor\`. Usually **no admin**. Good default for locked-down laptops.
   - **System installer** — installs for all users under `C:\Program Files\cursor\`. Needs **admin**. Better for shared machines or IT packaging.
4. Run the `.exe`, finish the wizard (keep “Add to PATH” if offered).
5. Open Cursor and sign in.

| Installer | Needs admin? | Typical path | Best when |
|-----------|--------------|--------------|-----------|
| User | Usually no | `%LOCALAPPDATA%\Programs\cursor\` | Personal use, no admin, company laptop |
| System | Yes | `%ProgramFiles%\cursor\` | Shared PC, IT deploys for everyone |

**Tip:** Do not keep both User and System installs on the same PC. Updates can fight each other. Pick one.

Architecture note: download **x64** for most PCs, or **ARM64** for Snapdragon / ARM Windows if listed on the download page.

## Path A — You have local admin

1. Download from [https://cursor.com/download](https://cursor.com/download).
2. Prefer **User** unless IT wants a machine-wide install; use **System** when packaging for all users.
3. Run the installer. If Windows asks for elevation (UAC), approve with your admin account.
4. If SmartScreen says “Windows protected your PC,” use **More info → Run anyway** only when you trust the official Cursor download.
5. Launch Cursor and sign in.

If antivirus or EDR still blocks the installer, do not disable security yourself — go to Path C or D.

## Path B — No admin (try per-user only)

1. Download the **User installer** (not System) from [https://cursor.com/download](https://cursor.com/download).
2. Run it. It should install under your user profile without asking for admin.
3. If it succeeds, open Cursor and sign in.
4. If you see blocks such as:
   - “This app has been blocked by your system administrator”
   - AppLocker / SmartScreen / company antivirus stop
   - Installer never starts or is deleted

   **Stop.** Do not try to crack Group Policy, turn off antivirus, or use unofficial copies. Go to Path C or D.

## Path C — Software Center / Company Portal / Intune

Many companies only allow apps from their catalog.

1. Open **Software Center** (ConfigMgr) or **Company Portal** (Intune).
2. Search for **Cursor**.
3. If listed, install from there (IT already approved it).
4. If not listed, use Path D and ask IT to add Cursor as an approved app.

## Path D — IT ticket (exception or deploy)

Ask IT for one of these (pick what matches your company):

| Ask for | What it means |
|---------|---------------|
| Approved app in Company Portal / Software Center | IT packages Cursor and you install the approved way |
| AppLocker / WDAC allow rule | Official Cursor installer (and app path) is allowed to run |
| Intune / MDM deployment | Cursor is pushed to your device or group |
| Local install exception | Temporary permission to run the User or System installer |

Helpful details to include in the ticket:

- Business reason (e.g. AI-assisted coding for project X)
- Link: `https://cursor.com/download`
- Preference: **User installer** under `%LOCALAPPDATA%\Programs\cursor\` (less privilege) or **System** if they prefer machine-wide
- Your PC name and username

## After install

1. **Sign in** with your Cursor account (work email if your org uses Cursor for teams).
2. **Optional:** import VS Code settings/extensions when Cursor offers that on first launch — useful if you already use VS Code.
3. **Corporate network gotchas (brief):**
   - Proxy or SSL inspection (HTTPS decryption) can break Cursor’s AI features or updates.
   - If chat/completions fail but the editor opens, ask IT about proxy allowlists or certificate trust — do not disable TLS checking yourself.
4. Updates: User installs usually update without admin; System installs may need IT or admin for some updates.

## What not to do

| Do not | Why |
|--------|-----|
| Bypass Group Policy / AppLocker | Breaks company policy; can be a security violation |
| Disable antivirus / EDR to force install | Leaves the PC unprotected; IT will flag it |
| Download cracked or mirrored installers | Malware risk; not supported |
| Install both User and System copies | Known updater conflicts on Windows |

## Data flow map

```
You
  |
  v
cursor.com/download
  |-- User .exe -----> %LOCALAPPDATA%\Programs\cursor\  (no admin ideal)
  |-- System .exe ---> Program Files\cursor\            (needs admin)
  |
  If blocked by GPO / AppLocker / AV
  |
  v
Software Center / Company Portal  OR  IT ticket
  |
  v
Approved Cursor on device
  |
  v
Sign in --> (optional) import VS Code settings
  |
  v
AI features --> company proxy / SSL inspect?
                 OK --> chat works
                 Fail --> ask IT (proxy / cert), do not bypass TLS
```

## Related files

| File | Role |
|------|------|
| [4-install-cursor-ad-windows.md](./4-install-cursor-ad-windows.md) | This guide |
| [4.sh](./4.sh) | Windows download / path one-liners (run on Windows; documented here for reference) |

## Commands

Windows commands live in [4.sh](./4.sh). Run them on the **Windows** PC (PowerShell or Command Prompt), not on Mac. Review with IT policy before downloading if your company restricts outbound installs.
