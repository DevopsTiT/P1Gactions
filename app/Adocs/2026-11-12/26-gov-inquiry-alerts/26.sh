mkdir -p "/Users/k/Work/AIProjects/Files/2026-11-12/26-gov-inquiry-alerts"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-11-12/26-gov-inquiry-alerts/." "/Users/k/Work/AIProjects/Files/2026-11-12/26-gov-inquiry-alerts/"
mkdir -p "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-11-12/26-gov-inquiry-alerts"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-11-12/26-gov-inquiry-alerts/." "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-11-12/26-gov-inquiry-alerts/"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" add "app/Adocs/2026-11-12/26-gov-inquiry-alerts"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" commit -m "Add the seven Gov Inquiry alerts from the Splunk forms."
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" push
