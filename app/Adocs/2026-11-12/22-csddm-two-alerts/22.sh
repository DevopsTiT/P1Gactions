mkdir -p "/Users/k/Work/AIProjects/Files/2026-11-12/22-csddm-two-alerts"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-11-12/22-csddm-two-alerts/." "/Users/k/Work/AIProjects/Files/2026-11-12/22-csddm-two-alerts/"
mkdir -p "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-11-12/22-csddm-two-alerts"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-11-12/22-csddm-two-alerts/." "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-11-12/22-csddm-two-alerts/"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" add "app/Adocs/2026-11-12/22-csddm-two-alerts"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" commit -m "Add the two CSDDM Splunk alerts as Dynatrace detectors."
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" push
