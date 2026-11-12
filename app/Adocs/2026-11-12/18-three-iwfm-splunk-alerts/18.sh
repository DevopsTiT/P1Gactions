mkdir -p "/Users/k/Work/AIProjects/Files/2026-11-12/18-three-iwfm-splunk-alerts"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-11-12/18-three-iwfm-splunk-alerts/." "/Users/k/Work/AIProjects/Files/2026-11-12/18-three-iwfm-splunk-alerts/"
mkdir -p "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-11-12/18-three-iwfm-splunk-alerts"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-11-12/18-three-iwfm-splunk-alerts/." "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-11-12/18-three-iwfm-splunk-alerts/"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" add "app/Adocs/2026-11-12/18-three-iwfm-splunk-alerts"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" commit -m "Add the three IWFM Splunk alerts as Dynatrace detectors."
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" push
