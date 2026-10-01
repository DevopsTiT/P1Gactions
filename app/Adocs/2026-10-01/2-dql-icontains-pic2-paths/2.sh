pbcopy < "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-01/2-dql-icontains-pic2-paths/2-dql-icontains-pic2-paths.dql"
mkdir -p "/Users/k/Work/AIProjects/Files/2026-10-01" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-01"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-01/2-dql-icontains-pic2-paths" "/Users/k/Work/AIProjects/Files/2026-10-01/"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-01/2-dql-icontains-pic2-paths" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-01/"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" add app/Adocs/2026-10-01
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" commit -m "Add DQL icontains pic2 check"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" push
