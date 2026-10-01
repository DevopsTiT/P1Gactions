/opt/splunkforwarder/bin/splunk btool inputs list --debug | grep -iE "ICM_CPW|/app/log/ap|IFDATA|HULFT|pltcomm|universal/log"
/opt/splunkforwarder/bin/splunk list monitor | grep -iE "ICM_CPW|/app/log/ap|IFDATA|HULFT|pltcomm|universal/log"
ls -l /app/ICM_CPW/log/ap/default.log /app/log/ap/default.log /app/ICM_CPW/log/sh/default.log /app/log/ap/monitoringTarget.log
ls -l /IFDATA/DATA/GE/LOG/SH/default.log /IFDATA/DATA/PC/LOG/PISP2/pisp2.log
ls -l /opt/HULFT/etc/trace /opt/HULFT/etc/BatchLog/HUL_JOB.LOG /opt/plat/logs/pltcomm.log /var/opt/universal/log/unv.log
sudo -u splunk head -1 /opt/HULFT/etc/BatchLog/HUL_JOB.LOG
sudo -u splunk head -1 /opt/HULFT/etc/trace
grep -iE "TailingProcessor|WatchedFile" /opt/splunkforwarder/var/log/splunk/splunkd.log | grep -iE "HULFT|ICM_CPW|IFDATA|pltcomm|unv.log" | tail -50
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-01/48-splunk-check-sources-in-index" "/Users/k/Work/AIProjects/Files/2026-10-01/"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-01/48-splunk-check-sources-in-index" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-01/"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git add app/Adocs/2026-10-01/48-splunk-check-sources-in-index
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git commit -m "docs: splunk check log paths in index"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git push
