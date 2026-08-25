# Dual Output P1Gactions Adocs

> **Path update (2026-08-25):** mirror is now `app/Adocs/` (this file was migrated from repo-root `Adocs/`). See seq `2-dual-write-app-adocs`.

```
Need answers on GitHub too?
  → Write CursorFiles Daily Files as usual
  → ALSO mirror under P1Gactions/app/Adocs/YYYY-MM-DD/<seq>-<slug>/
  → Put git add/commit/push one-liners in <seq>.sh
  → Auto-push? No — only when user says push / upload / commit

Wrong folder?
  answers/ or repo-root Adocs/ dated trees → wrong; use app/Adocs/

Which local clone?
  Prefer origin → DevopsTiT/P1Gactions
  → /Users/k/Codes/Pra/P1GithubActions/P1Gactions
```

## Short takeaway

| Key point | Detail |
|-----------|--------|
| What changed | Every Q&A (desktop or mobile) is dual-written |
| Local knowledge base | CursorFiles Daily Files (unchanged) |
| GitHub mirror | `app/Adocs/<date>/<seq>-<slug>/` in DevopsTiT/P1Gactions |
| Push | Commands in `.sh` for you; agents do not auto-push |
| Rule | Always-apply: `~/.cursor/rules/p1gactions-dual-answers.mdc` |

## Summary

From now on, agents still write answers into CursorFiles Daily Files. They also write the same artifacts into the P1Gactions repo under `Adocs/` with the same date / seq / slug layout, so mobile and desktop chats can land on GitHub when you push.

## Main content

### What this is

You asked that search/answers (including from mobile Cursor) also land in [DevopsTiT/P1Gactions](https://github.com/DevopsTiT/P1Gactions) under date folders. The folder name is **`Adocs`**, not `answers`.

### Correct local clone

| Path | Role |
|------|------|
| `/Users/k/Codes/Pra/P1GithubActions/P1Gactions` | Use this — `origin` is `https://github.com/DevopsTiT/P1Gactions.git` |
| `/Users/k/Codes/Pra/P1Githubed/P1Gactions` | Partial tree only; do not use for Adocs |

### Convention

```
P1Gactions/Adocs/
  YYYY-MM-DD/
    <seq>-<slug>/
      <seq>-<slug>.md
      <seq>.sh          # if commands
```

Same markdown rules as CursorFiles: H1 Title Case only, decision tree first, takeaway table, data flow in the same `.md`.

### Agent behavior

| Step | What happens |
|------|----------------|
| 1 | Write CursorFiles Daily File for today’s date and next seq |
| 2 | Mirror the same files under `Adocs/<date>/<seq>-<slug>/` |
| 3 | Append push one-liners to both `<seq>.sh` files |
| 4 | Do not `git push` unless you say push / upload / commit |

### Upload when you are ready

See companion [1.sh](1.sh). Typical flow:

1. Review `Adocs/` locally  
2. `git add Adocs/`  
3. Commit with a clear message  
4. `git push origin main`

## Data flow map

```
User question (desktop or mobile Cursor)
        │
        ▼
 Agent writes answer
        │
        ├──────────────► CursorFiles/Daily Files/YYYY-MM-DD/<seq>-<slug>/
        │                      <seq>-<slug>.md + <seq>.sh
        │
        └──────────────► P1Gactions/Adocs/YYYY-MM-DD/<seq>-<slug>/
                               <seq>-<slug>.md + <seq>.sh
                                      │
                                      ▼ (only when you run push)
                               GitHub DevopsTiT/P1Gactions
```

## Related files

| File | Purpose |
|------|---------|
| `~/.cursor/rules/p1gactions-dual-answers.mdc` | Always-apply dual-write rule |
| `~/.cursor/rules/cursorfiles-answers.mdc` | CursorFiles markdown structure |
| `/Users/k/Codes/Pra/P1GithubActions/P1Gactions/Adocs/README.md` | Repo-side Adocs convention |
| This folder’s `1.sh` | Inspect + optional upload commands |

## Commands

Inline reference — full list in [1.sh](1.sh).
