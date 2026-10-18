curl --request POST "https://sso.dynatrace.com/sso/oauth2/token" --header "Content-Type: application/x-www-form-urlencoded" --data-urlencode "grant_type=client_credentials" --data-urlencode "client_id=$DT_CLIENT_ID" --data-urlencode "client_secret=$DT_CLIENT_SECRET" --data-urlencode "scope=storage:logs:read" --data-urlencode "resource=urn:dtaccount:$DT_ACCOUNT_UUID"
curl --request GET "https://$DT_ENV_ID.apps.dynatrace.com/platform/..." --header "Authorization: Bearer $DT_PLATFORM_TOKEN"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-17/3-dynatrace-service-account
git commit -m "dynatrace service account explained"
git push
