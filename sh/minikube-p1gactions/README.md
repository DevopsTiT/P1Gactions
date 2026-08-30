# Terraform → Minikube (p1gactions)

Test case: apply the same Deployment/Service as `deploy/*.yaml` using the Terraform Kubernetes provider against local Minikube.

## Prerequisites

```sh
minikube start
minikube status
# load image so imagePullPolicy: Never works
docker pull --platform linux/amd64 ghcr.io/devopstit/p1gactions:latest
minikube image load ghcr.io/devopstit/p1gactions:latest
```

## Run

```sh
cd terraform/minikube-p1gactions
terraform init
terraform plan
terraform apply -auto-approve
kubectl get pods,svc -l app=p1gactions
kubectl port-forward svc/p1gactions 8080:80
curl -sS http://127.0.0.1:8080/health
```

## Destroy

```sh
terraform destroy -auto-approve
```

## Notes

- Provider uses `~/.kube/config` context `minikube` by default.
- Do not run this against a production cluster without changing `kube_context`.
- Alternative quick image: set `image = "nginx:1.27"` and `image_pull_policy = "IfNotPresent"` (remove /health probes or change path) — not identical to this app.
