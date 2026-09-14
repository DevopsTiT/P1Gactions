echo "Create Connection: Settings → Connections → Connectors → ServiceNow"
echo "Need: instance URL + Basic user/pass OR OAuth client id/secret"
echo "Also: Workflows Authorization → app-settings:objects:read"
echo "Then share Connection and select it on SNOW workflow tasks"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" add "app/Adocs/2026-09-14/4-create-servicenow-connection-steps"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" commit -m "docs: step-by-step create Dynatrace ServiceNow Connection"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" push
