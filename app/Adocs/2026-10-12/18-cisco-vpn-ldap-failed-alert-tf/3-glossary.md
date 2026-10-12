# Cisco VPN LDAP Glossary

| Term | What it means |
|---|---|
| Cisco ASA | Cisco firewall and VPN appliance. |
| LDAP | Protocol used to check user logins against Windows Active Directory. |
| Syslog | Standard way network devices send log lines to a collector. |
| Splunk index | Named log bucket in Splunk. No direct match in Dynatrace. |
| sourcetype | Splunk label for a log format. |
| Records detector | Dynatrace rule that runs DQL every minute and opens a problem when rows return. |
| `summarize count()` | Turns matching lines into one row holding the count. |
| Identity field | Field deciding whether a row belongs to an existing problem. |
| Ingestion delay | Time between a log being written and it being searchable. |
