# Getting Started

## What GitHub Actions is

GitHub Actions is automation that runs on GitHub’s machines when something happens in your repo (push, pull request, manual click).

You describe work in YAML under `.github/workflows/`.

## The two workflows in this project

| Workflow file | When it runs | What it does |
|---------------|--------------|--------------|
| `ci.yml` | Every push/PR to `main` | Install Python deps and run `pytest` |
| `build-and-push.yml` | Push to `main` that touches `app/` | Build Docker image and push to `ghcr.io` |

## Step-by-step first success

1. Create a GitHub repository (public is easiest for learning packages).
2. Push this project to `main`.
3. Open **Actions** → confirm **CI** is green.
4. Confirm **Build and push** is green.
5. Open **Packages** (right side of repo) → find `github-actions-starter` image tags `latest` and `sha-********`.

## Common failures

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| CI red on pytest | Code/test mismatch | Run `pytest` locally in `app/` |
| Build and push: denied | Workflow cannot write packages | Settings → Actions → Read and write permissions |
| Package not visible | Private package defaults | Package settings → link repo / visibility |
| Workflow did not run | Wrong branch or path filters | Push to `main`; change a file under `app/` |

## Pull an image locally (optional)

```sh
echo "$GITHUB_TOKEN" | docker login ghcr.io -u YOUR_GITHUB_USER --password-stdin
docker pull ghcr.io/YOUR_GITHUB_USER/github-actions-starter:latest
docker run --rm -p 8080:8080 ghcr.io/YOUR_GITHUB_USER/github-actions-starter:latest
curl http://127.0.0.1:8080/health
```

Use a classic PAT with `read:packages` if `GITHUB_TOKEN` is not available on your laptop.
