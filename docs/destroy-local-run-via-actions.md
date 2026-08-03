# Destroy local stack — run everything via GitHub Actions

Goal: wipe what is running on **your Mac** (Minikube/kubectl), then let **GitHub Actions** do CI → (optional) GHCR push → Minikube deploy + `/health` smoke test on the **GitHub runner**.

Important: Actions Minikube is **ephemeral on the runner**. It does **not** recreate pods on your laptop.

```
destroy local (Mac)
  → confirm kubectl empty of p1gactions
  → push to main (or re-run workflow)
  → Actions: CI test → Deploy to Minikube (runner) → Build and push (if app/** changed)
  → watch green checks on GitHub
```

---

## What “all” means here

| Layer | What to destroy / what Actions does |
|---|---|
| Local Minikube Deployment/Service/Pod | You delete on Mac |
| Local Docker container on `:8080` (if any) | You stop on Mac |
| Local Minikube cluster itself | Optional (`minikube stop` / `delete`) |
| GHCR image | Usually **keep**; Actions can rebuild/push |
| GitHub Actions runs | New runs on next push / manual re-run |

---

## Part A — Destroy local (Mac) — run these yourself

Do **not** skip: stop port-forwards first (Ctrl+C in those terminals).

### A1. Delete the app from local Kubernetes

```bash
cd /path/to/P1Gactions   # your clone

kubectl config current-context   # should be minikube
kubectl get all -l app=p1gactions

kubectl delete -f deploy/service.yaml -f deploy/deployment.yaml

# if manifests already gone but resources remain:
kubectl delete deployment,service,pod -l app=p1gactions --ignore-not-found

kubectl get all -l app=p1gactions
# expect: No resources found
```

### A2. Optional — stop a local Docker run of the app

```bash
docker ps --filter ancestor=ghcr.io/devopstit/p1gactions:latest
# if a container is running:
docker stop <container_id>
```

### A3. Optional — stop or delete local Minikube

```bash
# pause cluster (keeps data)
minikube stop

# OR wipe the whole local cluster
minikube delete
```

You do **not** need Minikube running locally for Actions to succeed.

### A4. Optional — remove local image copy

```bash
docker rmi ghcr.io/devopstit/p1gactions:latest
```

Skip this if you still want a local copy for later.

---

## Part B — What GitHub Actions will run

| Workflow | File | When | What it does |
|---|---|---|---|
| **CI** | `.github/workflows/ci.yml` | Push/PR to `main` | `pytest` |
| **Deploy to Minikube** (job inside CI) | same `ci.yml` | **Push to `main` only** (after tests) | Start Minikube on runner → `docker build` → `minikube image load` → `kubectl apply -f deploy/` → curl `/health` |
| **Build and push** | `.github/workflows/build-and-push.yml` | Push to `main` that touches `app/**` or that workflow file | Build multi-arch image → push `ghcr.io/devopstit/p1gactions` |

```
push main
  ├─ CI: test
  ├─ CI: deploy-minikube (runner only)  ← “whole process” for K8s smoke
  └─ Build and push (if app/** changed) ← GHCR publish
```

---

## Part C — Trigger the whole process via Actions

### C1. Preferred: push a change to `main`

```bash
git checkout main
git pull origin main

# make a small change so workflows run, e.g. touch app or workflow:
# - edit app/main.py or app/test_main.py  → CI + Deploy + Build and push
# - edit only docs/                      → CI may run; Build and push may NOT (path filter)

git add .
git commit -m "Trigger full CI and Minikube deploy on Actions"
git push origin main
```

Path filter reminder for **Build and push**:

- Runs only if the push includes changes under `app/**` or `.github/workflows/build-and-push.yml`
- To force image rebuild/push, change something under `app/`

### C2. Watch on GitHub

1. Open https://github.com/DevopsTiT/P1Gactions/actions  
2. Open the latest **CI** run → confirm:
   - **test** green  
   - **Deploy to Minikube** green (smoke `/health`)  
3. If `app/**` changed, open **Build and push** → confirm GHCR push green  

### C3. Re-run without a new commit

On an existing successful/failed run page:

- **Re-run all jobs** / **Re-run failed jobs**

That reuses the same commit; it does not change GHCR tags unless that workflow runs again and pushes.

---

## Part D — Verify (after Actions)

| Check | Where |
|---|---|
| Tests passed | Actions → CI → `test` |
| K8s deploy + health on runner | Actions → CI → `Deploy to Minikube` logs (port-forward + curl) |
| Image published | Actions → Build and push + repo **Packages** |
| Local Mac cluster | Still empty unless you deploy again with `docs/minikube.md` |

Local proof after destroy should look like:

```bash
kubectl get all -l app=p1gactions
# No resources found
```

---

## Part E — If you later want local Minikube again

Follow `docs/minikube.md` (load image → apply `deploy/` → port-forward). That is separate from Actions.

---

## Troubleshooting

| Symptom | Likely cause | What to do |
|---|---|---|
| Deploy job missing | Event was PR, not push to main | Merge/push to `main` |
| Build and push did not run | No `app/**` change | Touch a file under `app/` and push |
| Local pods still there | Delete not applied / wrong context | `kubectl config use-context minikube` then delete again |
| Expecting Mac Minikube from Actions | Wrong expectation | Actions only uses runner Minikube |

---

## Quick copy checklist

- [ ] Stop local port-forward  
- [ ] `kubectl delete -f deploy/service.yaml -f deploy/deployment.yaml`  
- [ ] Confirm no `p1gactions` resources locally  
- [ ] Optional: `minikube stop` or `minikube delete`  
- [ ] Push to `main` (include `app/**` if you want GHCR push)  
- [ ] Actions: CI test + Deploy to Minikube green  
- [ ] Actions: Build and push green (if triggered)  

---

## Related docs

| File | Role |
|---|---|
| `docs/minikube.md` | Local Mac Minikube deploy |
| `docs/getting-started.md` | First GHCR / Actions success |
| `.github/workflows/ci.yml` | Test + runner Minikube deploy |
| `.github/workflows/build-and-push.yml` | GHCR publish |
