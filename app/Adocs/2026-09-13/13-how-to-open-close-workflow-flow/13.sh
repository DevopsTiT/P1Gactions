echo "Edit assignMap + __SNOW_*__ + __PD_ROUTING_KEY__ in seq 4 YAML/JSON"
ls "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-09-13/4-snow-pd-workflow-yaml-and-json"
echo "Upload create workflow, then close workflow; set both Active"
echo "Open: prepare → parallel SNOW+PD → cross-link"
echo "Close: find correlation_id → resolve SNOW + PD"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" add "app/Adocs/2026-09-13/13-how-to-open-close-workflow-flow"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" commit -m "docs: detailed how-to for open close SNOW PD workflow flow"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" push
