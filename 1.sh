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

