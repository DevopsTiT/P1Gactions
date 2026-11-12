curl -X POST "https://YOUR_ENVIRONMENT.live.dynatrace.com/api/v2/entities/custom" -H "Authorization: Api-Token PASTE_TOKEN" -H "Content-Type: application/json" -d "{\"customDeviceId\":\"alj-sa-support-batch\",\"displayName\":\"ALJ SA Support Batch\",\"type\":\"alj-batch\",\"group\":\"ALJ alerts\"}"
mkdir -p "/Users/k/Work/AIProjects/Files/2026-11-12/36-attach-problem-entity"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-11-12/36-attach-problem-entity/." "/Users/k/Work/AIProjects/Files/2026-11-12/36-attach-problem-entity/"
mkdir -p "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-11-12/36-attach-problem-entity"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-11-12/36-attach-problem-entity/." "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-11-12/36-attach-problem-entity/"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" add "app/Adocs/2026-11-12/36-attach-problem-entity"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" commit -m "Explain how to attach a Davis log problem to a custom device."
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" push
