mkdir -p "/Users/k/Work/AIProjects/Files/2026-10-29/7-dql-all-applications"
mkdir -p "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-29/7-dql-all-applications"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-29/7-dql-all-applications/." "/Users/k/Work/AIProjects/Files/2026-10-29/7-dql-all-applications/"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-29/7-dql-all-applications/." "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-29/7-dql-all-applications/"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" add "app/Adocs/2026-10-29/7-dql-all-applications"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" commit -m "Add DQL that monitors every application on the queue metric."
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" push
