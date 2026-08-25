# Install Cursor Versus VS Code

```
want Cursor AI in the editor?
  │
  ├─ thought: "install Cursor inside VS Code as an extension"
  │     → STOP — that is not possible
  │     → Cursor is a separate app (VS Code fork), not a plugin
  │
  ├─ want full Cursor IDE (Agent, Composer, Tab, etc.)
  │     → download Cursor from cursor.com/download
  │     → macOS: open .dmg → drag to Applications → sign in
  │     → optional: Cursor Settings → General → Account → VS Code Import
  │     → File → Open Folder (same projects as VS Code)
  │
  └─ want AI *inside* existing VS Code only
        → use GitHub Copilot, Continue, or similar VS Code extensions
        → those are not Cursor
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| What Cursor is | A separate code editor, forked from VS Code, with built-in AI |
| What it is not | A VS Code extension you add from the marketplace |
| How to install (Mac) | Download `.dmg` from cursor.com → drag Cursor into Applications |
| Keep your VS Code setup | Cursor Settings → General → Account → VS Code Import |
| Same projects | Open the same folders in Cursor; both apps can coexist |
| AI only in VS Code | Use Copilot / Continue / similar — not Cursor |

## Summary

You cannot install “Cursor” inside VS Code like a normal extension. Cursor is its own app that looks and feels a lot like VS Code because it was built from that codebase. Install Cursor separately, optionally import your VS Code settings and extensions, then open your project folders in Cursor.

## 1. What Cursor is vs VS Code

| Concept | What it means | Why you care |
| --- | --- | --- |
| VS Code | Microsoft’s free editor | Your current familiar tool |
| Cursor | A separate editor forked from VS Code | Has Cursor’s AI (chat, agent, tab completions) built in |
| Fork | Same family / similar UI, but different product | Shortcuts and layout feel familiar; it is still a new app |
| Extension | A plugin that runs *inside* an editor | Cursor the product is not one of these |

Think of it like Chrome vs Brave: related, similar UI, but you install a different application — you do not “install Brave as a Chrome extension.”

## 2. Install Cursor on macOS

Official steps (from [cursor.com/help/getting-started/install](https://cursor.com/help/getting-started/install)):

1. Open [https://cursor.com/download](https://cursor.com/download) (or the Download button on [cursor.com](https://cursor.com)).
2. Download the macOS installer (`.dmg`). The site usually picks Apple Silicon vs Intel for you.
3. Double-click the `.dmg`.
4. Drag **Cursor** into the **Applications** folder.
5. Eject the disk image in Finder if you like.
6. Open Cursor from Applications (or Spotlight).
7. If macOS warns that the app was downloaded from the internet, choose **Open**.
8. Sign in with a Cursor account when prompted.

Optional: Homebrew users can also install with `brew install --cask cursor` (see `3.sh`).

## 3. Import from VS Code (optional)

If you already use VS Code on the same Mac:

1. Open **Cursor Settings**: `Cmd + Shift + J` (or Command Palette → “Cursor Settings”).
2. Go to **General** → **Account**.
3. Under **VS Code Import**, click **Import**.

That can bring over extensions, themes, settings, and keybindings.

Notes for beginners:

- Not every VS Code extension may appear or behave identically (Cursor uses the Open VSX registry, not the full VS Code Marketplace).
- You can keep using both Cursor and VS Code; they are separate apps.
- Official guide: [Migrate from VS Code](https://cursor.com/help/getting-started/migrate-vscode).

## 4. Open the same folders in Cursor

1. In Cursor: **File** → **Open Folder…**
2. Pick the same project directory you use in VS Code.
3. Your files on disk are shared; only the editor app changes.

You do not need to “move” the project. Cursor and VS Code can both open `/Users/you/my-project`.

## 5. What you cannot do

| Goal | Possible? | What to do instead |
| --- | --- | --- |
| Install full Cursor IDE as one VS Code plugin | No | Install the Cursor app |
| Get Cursor Agent / Composer *inside* stock VS Code via Cursor’s product | No | Use Cursor the app |
| Reuse themes/shortcuts from VS Code | Yes | Use VS Code Import in Cursor Settings |

## 6. If you want AI inside VS Code instead

Stay in VS Code and install an AI extension there, for example:

| Option | What it is |
| --- | --- |
| GitHub Copilot | Popular AI pair-programmer extension for VS Code |
| Continue | Open-source AI coding assistant that can run in VS Code |

Those give AI help *inside* VS Code. They are not Cursor, and they do not install the Cursor IDE.

## Data flow map

```
You (want Cursor)
        │
        ▼
cursor.com/download  →  Cursor.app (.dmg)
        │
        ▼
Applications/Cursor.app  →  sign in
        │
        ├─ optional: VS Code Import  ←──  ~/.vscode (settings, extensions)
        │
        └─ File → Open Folder  ←──  same project folder as VS Code
                    │
                    ▼
              edit + Cursor AI in Cursor
```

```
Wrong mental model (does not work):

VS Code → Extensions marketplace → "Cursor IDE" plugin → full Cursor
```

## Related files

| File | Role |
| --- | --- |
| [3.sh](./3.sh) | One-liner commands (open download page, optional brew, git push helpers) |
| [Official install](https://cursor.com/help/getting-started/install) | Cursor install help |
| [Migrate from VS Code](https://cursor.com/help/getting-started/migrate-vscode) | VS Code Import steps |
| CursorFiles | `/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-08-25/3-install-cursor-versus-vscode/` |

## Commands

Run the one-liners in [3.sh](./3.sh) yourself (do not assume they were executed). Primary action: open the official download page in your browser.
