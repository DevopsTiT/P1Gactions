# Redeploy after local destroy

You deleted local `p1gactions` (Deployment + Service). Choose **where** you want it again.

```
want pods on YOUR Mac Minikube?
  → Part A (local redeploy)

want only GitHub Actions to deploy + smoke-test?
  → Part B (Actions) — does NOT recreate Mac resources
```

| Goal | Method |
|---|---|
| App running again on laptop Minikube | Part A |
| CI proves deploy on GitHub runner | Part B |
| Both | Do A and B |

---

## Part A — Redeploy on local Minikube (Mac)

Requires Minikube running and context `minikube`.

```bash
cd /path/to/P1Gactions

minikube status
kubectl config use-context minikube

# load image into minikube (needed with imagePullPolicy: Never)
minikube image load ghcr.io/devopstit/p1gactions:latest

# if load fails / no local image:
#   docker pull --platform linux/amd64 ghcr.io/devopstit/p1gactions:latest
#   minikube image load ghcr.io/devopstit/p1gactions:latest

kubectl apply -f deploy/deployment.yaml
kubectl apply -f deploy/service.yaml

kubectl rollout status deployment/p1gactions
kubectl get pods,svc -l app=p1gactions
```

### Test locally

```bash
kubectl port-forward svc/p1gactions 8080:80
# other terminal:
curl -sS http://127.0.0.1:8080/health
curl -sS http://127.0.0.1:8080/
```

Or: `minikube service p1gactions --url` (NodePort 30080).

### One-liner apply (after image is loaded)

```bash
kubectl apply -f deploy/
```

(`deploy/` must contain only the intended YAMLs.)

---

## Part B — Redeploy via GitHub Actions (runner only)

This runs the **Deploy to Minikube** job inside `ci.yml` on a **GitHub-hosted runner**.  
It will **not** show `p1gactions` again when you run `kubectl get all` on your Mac.

### Trigger

```bash
git checkout main
git pull origin main

# need a push to main; include app/** if you also want Build and push
# e.g. tiny change under app/ or empty commit:
git commit --allow-empty -m "Trigger CI Minikube redeploy"
git push origin main
```

### Watch

1. https://github.com/DevopsTiT/P1Gactions/actions  
2. Open latest **CI** run on `main`  
3. Confirm **test** + **Deploy to Minikube** are green  

PR-only runs: tests may run; **Deploy to Minikube** runs only on **push to `main`**.

### Re-run without new commit

Actions → open a past **CI** run on `main` → **Re-run all jobs**.

---

## Quick decision

| You want… | Run |
|---|---|
| `kubectl get all` shows p1gactions again | **Part A** |
| Green Actions deploy log only | **Part B** |

---

## Related

| File | Role |
|---|---|
| `docs/minikube.md` | Local deploy details |
| `docs/destroy-local-run-via-actions.md` | Destroy + Actions overview |
| `deploy/deployment.yaml` | App Deployment |
| `deploy/service.yaml` | NodePort Service |
| `.github/workflows/ci.yml` | Test + runner Minikube |
