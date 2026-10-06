cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-06/4-cisco-vpn-ldap-records-detector"
terraform init
terraform validate
terraform plan
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-06/4-cisco-vpn-ldap-records-detector" "/Users/k/Work/AIProjects/Files/2026-10-06/"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-06/4-cisco-vpn-ldap-records-detector" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-06/"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git add app/Adocs/2026-10-06/4-cisco-vpn-ldap-records-detector/*.md app/Adocs/2026-10-06/4-cisco-vpn-ldap-records-detector/*.txt app/Adocs/2026-10-06/4-cisco-vpn-ldap-records-detector/*.tf app/Adocs/2026-10-06/4-cisco-vpn-ldap-records-detector/*.dql
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git commit -m "docs: Cisco VPN LDAP alert as Records detector without makeTimeseries"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git push
