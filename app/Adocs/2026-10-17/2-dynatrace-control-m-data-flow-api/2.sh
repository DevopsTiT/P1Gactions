curl -H "x-api-key: $CTM_TOKEN" "$CTM_ENDPOINT/run/jobs/status?limit=10"
curl -H "Authorization: Bearer $CTM_TOKEN" "$CTM_ENDPOINT/run/jobs/status?status=Ended%20Not%20OK&limit=10"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-17/2-dynatrace-control-m-data-flow-api
git commit -m "dynatrace control-m data flow and api"
git push
