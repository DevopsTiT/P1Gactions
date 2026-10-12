# Cisco VPN LDAP Log Source Investigation

| What was checked | Finding |
|---|---|
| User query in `6.sh` | `fetch logs`, `log.source` contains `/var/log/ASA`, content contains `Windows_LDAP as FAILED`, both ignoring case. |
| Splunk sources for cisco:asa | Four files, all under `/var/log/ASA/`. |
| Largest source | JPNDH-VASA19-ALJ.log with 88.6% of events. |
| FAILED events in Splunk | 2 between 9/12 and 10/12. |
| Missing in user query | Time window. Added `from:now()-5m`. |
| Secrets | None visible. |
