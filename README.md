# GitHub Actions Starter

Beginner CI project: **test on every PR**, **build and push a Docker image to GHCR on `main`**.

## What this teaches

| Idea | Plain English |
|------|---------------|
| GitHub Actions | GitHub runs your automation when you push or open a PR |
| Workflow | A YAML file under `.github/workflows/` that defines jobs |
| Job | A set of steps on a runner (here: `ubuntu-latest`) |
| GHCR | GitHub Container Registry — `ghcr.io/<owner>/<repo>` |

## Pipeline

```
Pull request
  → ci.yml → install Python → pytest
  → (optional) docker build without push

Push to main
  → ci.yml → pytest
  → build-and-push.yml → build image → push to ghcr.io
```

## Layout

```
github-actions-starter/
├── app/
│   ├── main.py            # Tiny FastAPI app
│   ├── requirements.txt
│   ├── Dockerfile
│   └── test_main.py       # Unit tests for CI
├── .github/workflows/
│   ├── ci.yml             # Lint-ish checks + pytest
│   └── build-and-push.yml # Build/push image on main
├── docs/
│   └── getting-started.md
└── README.md
```

## Quick start

1. Create an empty GitHub repo (example name: `github-actions-starter`).
2. From this folder, set remote and push (see commands below).
3. Open the repo → **Actions** tab → watch `CI` run.
4. After a green `main` push, check **Packages** for the image under GHCR.

### First push

```sh
cd /Users/k/Codes/github-actions-starter
git remote add origin https://github.com/<YOUR_GITHUB_USER>/github-actions-starter.git
git branch -M main
git add .
git commit -m "Initial GitHub Actions starter"
git push -u origin main
```

### Make Actions able to push packages

Repo → **Settings** → **Actions** → **General** → Workflow permissions:

- Read and write permissions
- Allow GitHub Actions to create and approve pull requests (optional)

For private packages visibility: Package settings → change visibility / link to repo as needed.

## Local commands (optional)

```sh
cd app
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
pytest -q
uvicorn main:app --reload --port 8080
# curl http://127.0.0.1:8080/health
```

## Stretch goals (after it works)

| Goal | Change |
|------|--------|
| PR-only tests | Keep `ci.yml`; leave `build-and-push.yml` on `main` only (already true) |
| Image scan | Add Trivy before push |
| Deploy | Add ArgoCD or `kubectl` job later (separate from this starter) |
| Matrix | Test on Python 3.11 and 3.12 |

## Safety

- No kubeconfig in Actions for this project
- Uses `GITHUB_TOKEN` only (no long-lived PAT required for GHCR push when permissions are set)
