mkdir -p "/Users/k/Work/AIProjects/Files/2026-11-16/14-mg-up-check-job-name"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-11-16/14-mg-up-check-job-name/." "/Users/k/Work/AIProjects/Files/2026-11-16/14-mg-up-check-job-name/"
mkdir -p "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-11-16/14-mg-up-check-job-name"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-11-16/14-mg-up-check-job-name/." "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-11-16/14-mg-up-check-job-name/"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" add "app/Adocs/2026-11-16/14-mg-up-check-job-name"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" commit -m "Add DQL for the two-host up-check using restapi.job_name."
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" push
