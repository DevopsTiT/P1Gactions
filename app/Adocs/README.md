# app/Adocs (Cursor dual-write)

Date-based Q&A answers mirrored from Cursor sessions (desktop and mobile) into this repo for review and upload to GitHub.

**Why under `app/Adocs/`:** `app/` is the FastAPI service (`main.py`, Dockerfile). Q&A lives in `Adocs/` inside `app/` so Python imports and the image stay clean, while still satisfying “into the folder of app”.

**Remote:** [DevopsTiT/P1Gactions](https://github.com/DevopsTiT/P1Gactions)

Local clone used by agents:

`/Users/k/Codes/Pra/P1GithubActions/P1Gactions`

## Folder convention

```
app/Adocs/
  YYYY-MM-DD/
    <seq>-<slug>/
      <seq>-<slug>.md    # main answer (same structure as CursorFiles Daily Files)
      <seq>.sh           # optional; one command per line
```

| Piece | Meaning |
|-------|---------|
| `YYYY-MM-DD` | Answer date (same calendar day as CursorFiles) |
| `<seq>` | Integer starting at 1 each day; increments per question |
| `<slug>` | Short kebab-case summary (3–6 words) |

## Dual-write policy

Agents still write **CursorFiles** under:

`/Users/k/Learnings/AIProject/CursorFiles/Daily Files/<date>/<seq>-<slug>/`

and **also** write the same artifacts here under `app/Adocs/<date>/<seq>-<slug>/`.

## Not these paths

| Path | Why not |
|------|---------|
| `app/<date>/...` | Would mix docs into the FastAPI package root |
| Repo-root `Adocs/` | Superseded; see pointer README there |
| `answers/` | Old name; do not use |

## Upload (you run these)

Agents do **not** auto-push. From the repo root:

```sh
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/
git status
git commit -m "Add app/Adocs for YYYY-MM-DD"
git push origin main
```

First push of this convention: commit `app/Adocs/README.md` (and any dated folders) when ready.
