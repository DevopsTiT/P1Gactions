cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/35-broker-policy-maintenance-readiness-probe-tf"
terraform init
terraform validate
terraform plan
terraform apply
kubectl get pods -A | grep broker-policy-maintenance
kubectl describe pod -n <namespace> <pod-name>
kubectl get events -n <namespace> --field-selector reason=Unhealthy
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-08/35-broker-policy-maintenance-readiness-probe-tf
git commit -m "Add broker-policy-maintenance readiness probe detector migrated from Splunk"
git push
