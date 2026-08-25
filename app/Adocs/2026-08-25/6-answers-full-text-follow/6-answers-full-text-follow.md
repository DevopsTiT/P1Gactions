# Answers Full Text Follow

```
User sees only “说明：Daily Files/…” in chat?
  → Bad. Chat must carry the full useful answer (text follow)
  → Also dual-write CursorFiles + app/Adocs/
  → Prefer add <seq>-<slug>-follow.txt (same chat-ready steps)
  → Path pointer alone is never enough

New Q&A answer?
  → Write full steps in chat first (follow-along)
  → Write Daily Files/<date>/<seq>-slug/
  → Mirror app/Adocs/<date>/<seq>-slug/
  → Optional: *-follow.txt in both folders
  → Push? only if user says push / upload / commit
```

## Short takeaway

| Key point | Detail |
|-----------|--------|
| What changed | Every answer must show **full useful text in chat**, not only a folder pointer |
| Why | Mobile and quick search need follow-along; opening Daily Files is optional |
| Dual-write | Still write CursorFiles **and** `app/Adocs/` |
| Follow file | Preferred: `<seq>-<slug>-follow.txt` with the same chat-ready steps |
| Rule file | `~/.cursor/rules/p1gactions-dual-answers.mdc` |
| Push | Still manual; agents do not auto-push |

## Summary

After a Cursor Windows CLI install answer looked like a short “说明：Daily Files/…” pointer, you asked for **text follow**: the chat itself must carry the full steps. Disk dual-write stays. An optional plain `.txt` follow file makes mobile copy easier. This seq documents that persistent preference.

## Main content

### What this is

**Text follow** means the agent puts the complete, useful answer in the chat reply (English and/or Chinese as needed), so you can read and copy without opening a folder first.

### Why it matters

| Situation | Problem if chat is path-only | Fix |
|-----------|------------------------------|-----|
| Mobile Cursor search | Hard to open long macOS paths | Full steps in chat + optional `.txt` |
| Quick install how-to | You need commands now | Paste winget / PowerShell in chat |
| Later archive | You still want GitHub / Daily Files | Dual-write unchanged |

### Required behavior (every Q&A)

| Step | What to do |
|------|------------|
| 1. Chat | Full useful answer text (steps, commands, decisions) |
| 2. CursorFiles | `Daily Files/<YYYY-MM-DD>/<seq>-<slug>/` per cursorfiles-answers |
| 3. Adocs mirror | `P1Gactions/app/Adocs/<YYYY-MM-DD>/<seq>-<slug>/` |
| 4. Follow file (preferred) | `<seq>-<slug>-follow.txt` in both folders |
| 5. Push | Only when user says push / upload / commit |

### Folder layout after this rule

```
Daily Files/YYYY-MM-DD/<seq>-<slug>/
  <seq>-<slug>.md
  <seq>.sh
  <seq>-<slug>-follow.txt

app/Adocs/YYYY-MM-DD/<seq>-<slug>/
  <seq>-<slug>.md
  <seq>.sh
  <seq>-<slug>-follow.txt
```

### Demo: winget install Cursor (text follow)

Run on **Windows** PowerShell or cmd (not macOS agent).

**English — preferred path**

1. Confirm network to winget / cursor.com is allowed (AD/Intune may block).
2. Search: `winget search Cursor`
3. Install exact ID: `winget install --id Anysphere.Cursor --exact`
4. No admin? Prefer user scope: `winget install --id Anysphere.Cursor --exact --scope user`
5. Quiet-ish: `winget install --id Anysphere.Cursor --exact --silent --accept-package-agreements --accept-source-agreements`
6. If AppLocker / Software Center blocks → do not bypass; use IT / Company Portal (see seq 4).

**中文 — 推荐路径**

1. 确认本机网络允许访问 winget 源和 cursor.com（公司 AD/Intune 可能拦截）。
2. 搜索：`winget search Cursor`
3. 精确安装：`winget install --id Anysphere.Cursor --exact`
4. 无管理员权限时优先用户范围：`winget install --id Anysphere.Cursor --exact --scope user`
5. 静默示例：`winget install --id Anysphere.Cursor --exact --silent --accept-package-agreements --accept-source-agreements`
6. 若 AppLocker / 软件中心拦截 → 不要绕过策略；走 IT / Company Portal（见 seq 4）。

Package ID: **Anysphere.Cursor**. CLI does not skip company policy.

### Rule change checklist

| Item | Status |
|------|--------|
| Update `p1gactions-dual-answers.mdc` | Done this seq |
| Chat full-text follow | Always required |
| Dual-write Daily + Adocs | Always required |
| `*-follow.txt` | Preferred |
| Auto-push | Still forbidden unless user asks |

## Data flow map

```
User question (search / chat)
  → Agent writes FULL answer text in chat (text follow)
  → Same content → CursorFiles Daily Files/<date>/<seq>-slug/
  → Mirror → P1Gactions/app/Adocs/<date>/<seq>-slug/
  → Optional → <seq>-slug-follow.txt (copy-ready)
  → User runs commands themselves
  → git push only if user says push/upload/commit
```

## Related files

| File | Role |
|------|------|
| [6-answers-full-text-follow.md](./6-answers-full-text-follow.md) | This doc |
| [6-answers-full-text-follow-follow.txt](./6-answers-full-text-follow-follow.txt) | Chat-ready follow text |
| [6.sh](./6.sh) | Optional commit/push one-liners (manual) |
| `~/.cursor/rules/p1gactions-dual-answers.mdc` | Always-apply rule (updated) |
| [../5-install-cursor-windows-cli/5-install-cursor-windows-cli.md](../5-install-cursor-windows-cli/5-install-cursor-windows-cli.md) | Winget CLI detail |
| Mirror | `Pra/P1GithubActions/P1Gactions/app/Adocs/2026-08-25/6-answers-full-text-follow/` |

## Commands

One-liners in [6.sh](./6.sh). Agents do **not** run push unless you ask.
