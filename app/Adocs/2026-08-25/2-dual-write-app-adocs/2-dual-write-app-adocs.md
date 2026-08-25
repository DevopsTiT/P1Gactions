# Dual Write App Adocs

```
User said answers go under app/
  → Is app/ FastAPI code? (main.py / Dockerfile)
      yes → use app/Adocs/YYYY-MM-DD/<seq>-<slug>/
      no  → use app/YYYY-MM-DD/<seq>-<slug>/
  → Repo-root Adocs/? → obsolete; pointer README only
  → Dump .md next to main.py? → never
  → Auto-push? → no; one-liners in <seq>.sh only
```

## Short takeaway

| Key point | Detail |
|-----------|--------|
| What changed | GitHub mirror moved under `app/Adocs/` |
| Why not `app/` root | `app/` is FastAPI (`main.py`); keep docs out of the package root |
| CursorFiles | Unchanged under Daily Files |
| Old path | Repo-root `Adocs/` is a pointer only |
| Rule | `~/.cursor/rules/p1gactions-dual-answers.mdc` |
| Push | You run commands in `.sh`; agents do not auto-push |

## Summary

You asked for dual-write “into the folder of app” on DevopsTiT/P1Gactions. Inspection showed `app/` is the FastAPI service, so dated Q&A goes under `app/Adocs/` — still inside app, without breaking Python layout. Agents dual-write CursorFiles plus this mirror; push stays manual.

## Main content

### What this is

Mobile and desktop Cursor answers still land in CursorFiles. They also mirror into the P1Gactions clone so you can upload to GitHub. The parent folder is **`app/`**, but because that directory is application code, the dated tree is **`app/Adocs/`**.

### Inspection result

| Path | What it is |
|------|------------|
| `app/main.py` | FastAPI app |
| `app/Dockerfile` | Container build for the API |
| `app/requirements.txt` | Python deps |
| `app/test_main.py` | Tests |
| `app/Adocs/` | **New** Q&A mirror (safe subdirectory) |

### Final path convention

```
P1Gactions/app/Adocs/
  YYYY-MM-DD/
    <seq>-<slug>/
      <seq>-<slug>.md
      <seq>.sh          # if commands
```

Local full path:

`/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/<YYYY-MM-DD>/<seq>-<slug>/`

Same date / seq / slug as CursorFiles when possible.

### Paths to avoid

| Path | Why |
|------|-----|
| `app/2026-08-25/...` | Mixes markdown into the FastAPI package root |
| Repo-root `Adocs/YYYY-MM-DD/...` | Superseded; only a pointer README remains |
| `answers/` | Old name; do not use |

### Migration done locally

| Action | Result |
|--------|--------|
| Created | `app/Adocs/README.md` + dated folders |
| Moved | Prior `Adocs/2026-08-25/1-...` → `app/Adocs/2026-08-25/1-...` |
| Left | Repo-root `Adocs/README.md` pointing at `app/Adocs/` |
| Updated | Always-apply rule `p1gactions-dual-answers.mdc` |

### Agent behavior going forward

| Step | What happens |
|------|----------------|
| 1 | Write CursorFiles Daily File for today’s date and next seq |
| 2 | Mirror the same files under `app/Adocs/<date>/<seq>-<slug>/` |
| 3 | Put `git add` / `commit` / `push` one-liners in both `<seq>.sh` files |
| 4 | Do not push or commit unless you say push / upload / commit |

## Data flow map

```
User question (desktop or mobile Cursor)
        │
        ▼
 Agent writes answer
        │
        ├──────────────► CursorFiles/Daily Files/YYYY-MM-DD/<seq>-<slug>/
        │
        └──────────────► P1Gactions/app/Adocs/YYYY-MM-DD/<seq>-<slug>/
                               │
                               ▼ (only when you run push)
                         GitHub DevopsTiT/P1Gactions
```

## Related files

| File | Purpose |
|------|---------|
| `~/.cursor/rules/p1gactions-dual-answers.mdc` | Always-apply dual-write rule (updated) |
| `/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/README.md` | Repo convention |
| `/Users/k/Codes/Pra/P1GithubActions/P1Gactions/Adocs/README.md` | Pointer to new path |
| This folder’s `2.sh` | Inspect + optional upload commands |

## Commands

Inline reference — full list in [2.sh](2.sh).
