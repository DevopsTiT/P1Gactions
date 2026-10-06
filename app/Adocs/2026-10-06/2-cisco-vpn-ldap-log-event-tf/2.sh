cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-06/2-cisco-vpn-ldap-log-event-tf"
terraform init
terraform validate
terraform plan
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-06/2-cisco-vpn-ldap-log-event-tf" "/Users/k/Work/AIProjects/Files/2026-10-06/"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-06/2-cisco-vpn-ldap-log-event-tf" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-06/"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git add app/Adocs/2026-10-06/2-cisco-vpn-ldap-log-event-tf/*.md app/Adocs/2026-10-06/2-cisco-vpn-ldap-log-event-tf/*.txt app/Adocs/2026-10-06/2-cisco-vpn-ldap-log-event-tf/*.tf app/Adocs/2026-10-06/2-cisco-vpn-ldap-log-event-tf/*.dql
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git commit -m "docs: Cisco VPN LDAP alert as Dynatrace log event without makeTimeseries"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git push
