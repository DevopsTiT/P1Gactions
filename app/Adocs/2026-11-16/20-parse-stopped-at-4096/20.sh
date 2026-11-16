mkdir -p "/Users/k/Work/AIProjects/Files/2026-11-16/20-parse-stopped-at-4096"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-11-16/20-parse-stopped-at-4096/." "/Users/k/Work/AIProjects/Files/2026-11-16/20-parse-stopped-at-4096/"
mkdir -p "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-11-16/20-parse-stopped-at-4096"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-11-16/20-parse-stopped-at-4096/." "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-11-16/20-parse-stopped-at-4096/"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" add "app/Adocs/2026-11-16/20-parse-stopped-at-4096"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" commit -m "Let the API parse read past the 4096 character stop."
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" push
