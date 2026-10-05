logger -n <SYSLOG_COLLECTOR_HOST> -P 514 -d "%ASA-2-113022: AAA Marking LDAP server 10.0.0.1 in aaa-server group Windows_LDAP as FAILED (DT test 1)"
logger -n <SYSLOG_COLLECTOR_HOST> -P 514 -d "%ASA-2-113022: AAA Marking LDAP server 10.0.0.1 in aaa-server group Windows_LDAP as FAILED (DT test 2)"
logger -n <SYSLOG_COLLECTOR_HOST> -P 514 -d "%ASA-2-113022: AAA Marking LDAP server 10.0.0.1 in aaa-server group Windows_LDAP as FAILED (DT test 3)"
logger -n <SYSLOG_COLLECTOR_HOST> -P 514 -d "%ASA-2-113022: AAA Marking LDAP server 10.0.0.1 in aaa-server group Windows_LDAP as FAILED (DT test 4)"
mkdir -p "/Users/k/Work/AIProjects/Files/2026-10-05" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-05"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/3-cisco-vpn-ldap-alert-to-dynatrace" "/Users/k/Work/AIProjects/Files/2026-10-05/"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/3-cisco-vpn-ldap-alert-to-dynatrace" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-05/"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git add app/Adocs/2026-10-05/3-cisco-vpn-ldap-alert-to-dynatrace/*.md app/Adocs/2026-10-05/3-cisco-vpn-ldap-alert-to-dynatrace/*.txt
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git commit -m "docs: Cisco VPN LDAP Splunk alert converted to Dynatrace"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git push
