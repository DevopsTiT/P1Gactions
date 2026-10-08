cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/34-broker-policy-maintenance-host-count-tf"
terraform init
terraform validate
terraform plan
terraform apply
kubectl get deploy broker-policy-maintenance-web -A
kubectl get pods -A -l app=broker-policy-maintenance-web
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-08/34-broker-policy-maintenance-host-count-tf
git commit -m "Add broker-policy-maintenance host count detector migrated from Splunk"
git push
