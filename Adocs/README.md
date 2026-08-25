# Moved — use `app/Adocs/`

Q&A dual-write no longer lives at repo-root `Adocs/`.

**Canonical path:** [`app/Adocs/`](../app/Adocs/README.md)

```
P1Gactions/app/Adocs/YYYY-MM-DD/<seq>-<slug>/
```

Reason: `app/` is the FastAPI package; dated answers go under `app/Adocs/` so they stay under “app” without polluting `main.py` / imports.

Do not add new dated folders here.
