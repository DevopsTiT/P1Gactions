# Deploy to local Minikube

Your Mac is arm64; the current GHCR image is linux/amd64. Minikube can still run it after you load the local image (Docker Desktop emulates amd64).

## Steps

```sh
# 1) Make sure minikube is running
minikube status

# 2) Load the image you already have in Docker Desktop into minikube
minikube image load ghcr.io/devopstit/p1gactions:latest

# 3) Apply manifests (imagePullPolicy: Never → use loaded image)
kubectl apply -f deploy/deployment.yaml
kubectl apply -f deploy/service.yaml

# 4) Wait for Ready
kubectl rollout status deployment/p1gactions
kubectl get pods,svc -l app=p1gactions

# 5) Test
# Option A — port-forward
kubectl port-forward svc/p1gactions 8080:80
# other terminal:
curl -sS http://127.0.0.1:8080/health
curl -sS http://127.0.0.1:8080/

# Option B — minikube service URL (NodePort 30080)
minikube service p1gactions --url
```

## Cleanup

```sh
kubectl delete -f deploy/service.yaml -f deploy/deployment.yaml
```

## If ImagePullBackOff

| Cause | Fix |
|---|---|
| Forgot `minikube image load` | Run load, then `kubectl delete pod -l app=p1gactions` |
| Pulling from GHCR instead of local | Keep `imagePullPolicy: Never` for local demos |
| Private GHCR | Either load locally, or create imagePullSecret |

## If CrashLoop / platform issues

Pull/run with amd64 first to confirm the image works, then reload into minikube:

```sh
docker pull --platform linux/amd64 ghcr.io/devopstit/p1gactions:latest
minikube image load ghcr.io/devopstit/p1gactions:latest
kubectl delete pod -l app=p1gactions
```

## GitHub Actions (CI runner Minikube)

`CI` workflow job **Deploy to Minikube** runs only on **push to `main`** after tests pass.

It starts Minikube **on the GitHub-hosted runner**, builds `ghcr.io/devopstit/p1gactions:latest`, runs `minikube image load`, applies `deploy/`, then curls `/health`.

That does **not** deploy to Minikube on your Mac. For local Mac deploy, keep using the steps above (or a self-hosted runner on your machine).

