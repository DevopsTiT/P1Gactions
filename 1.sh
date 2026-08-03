curl -sS http://127.0.0.1:8080/health

curl -sS http://127.0.0.1:8080/

echo "$GITHUB_TOKEN" | docker login ghcr.io -u DevopsTiT --password-stdin
docker pull ghcr.io/devopstit/p1gactions:latest
docker run --rm -p 8080:8080 ghcr.io/devopstit/p1gactions:latest

cd /Users/k/Codes/Pra/P1Githubactions/P1Gactions/app
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8080

docker pull --platform linux/amd64 ghcr.io/devopstit/p1gactions:latest
docker run --platform linux/amd64 --rm -p 8080:8080 ghcr.io/devopstit/p1gactions:latest
curl -sS http://127.0.0.1:8080/health

# image already in Docker Desktop → load into minikube
minikube image load ghcr.io/devopstit/p1gactions:latest
kubectl apply -f deploy/deployment.yaml
kubectl apply -f deploy/service.yaml
kubectl rollout status deployment/p1gactions

kubectl delete -f deploy/service.yaml -f deploy/deployment.yaml

git commit --allow-empty -m "Trigger CI Minikube redeploy"
git push origin main

minikube image load ghcr.io/devopstit/p1gactions:latest
kubectl apply -f deploy/deployment.yaml
kubectl apply -f deploy/service.yaml
kubectl rollout status deployment/p1gactions
kubectl port-forward svc/p1gactions 8080:80

git pull --rebase origin main
git push origin main

git status
git stash push -u -m "wip before rebase"
git pull --rebase origin main
git push origin main
git stash pop

# 1) park 1.sh only
git stash push -m "1.sh wip" -- 1.sh
# 2) commit the files you want (not 1.sh)
git add docs/destroy-local-run-via-actions.md docs/redeploy-after-destroy.md terraform/
git commit -m "Add redeploy docs and minikube Terraform module."
# 3) sync + push (no git config needed)
git pull --rebase origin main
git push origin main
# 4) restore 1.sh locally
git stash pop