cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-06/5-cisco-vpn-ldap-two-alerts-tf"
terraform init
terraform validate
terraform plan
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-06/5-cisco-vpn-ldap-two-alerts-tf" "/Users/k/Work/AIProjects/Files/2026-10-06/"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-06/5-cisco-vpn-ldap-two-alerts-tf" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-06/"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git add app/Adocs/2026-10-06/5-cisco-vpn-ldap-two-alerts-tf/*.md app/Adocs/2026-10-06/5-cisco-vpn-ldap-two-alerts-tf/*.txt app/Adocs/2026-10-06/5-cisco-vpn-ldap-two-alerts-tf/*.tf app/Adocs/2026-10-06/5-cisco-vpn-ldap-two-alerts-tf/*.dql
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git commit -m "docs: two Cisco VPN LDAP Splunk alerts as Dynatrace Records detectors in one file"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git push
