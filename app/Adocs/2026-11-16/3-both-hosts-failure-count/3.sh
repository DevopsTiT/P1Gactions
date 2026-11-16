mkdir -p "/Users/k/Work/AIProjects/Files/2026-11-16/3-both-hosts-failure-count"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-11-16/3-both-hosts-failure-count/." "/Users/k/Work/AIProjects/Files/2026-11-16/3-both-hosts-failure-count/"
mkdir -p "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-11-16/3-both-hosts-failure-count"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-11-16/3-both-hosts-failure-count/." "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-11-16/3-both-hosts-failure-count/"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" add "app/Adocs/2026-11-16/3-both-hosts-failure-count"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" commit -m "Combine both APIGW hosts into one failure count DQL."
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" push
