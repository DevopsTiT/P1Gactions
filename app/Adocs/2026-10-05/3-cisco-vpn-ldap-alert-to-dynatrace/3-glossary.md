# Glossary

| Term | What it means |
|---|---|
| Cisco ASA | Cisco's firewall and VPN appliance |
| LDAP | The protocol the VPN uses to check usernames and passwords against Active Directory |
| AAA server group | A list of authentication servers on the ASA; here it is called `Windows_LDAP` |
| Marked FAILED | The ASA stopped trusting that LDAP server because it did not answer |
| syslog | The standard way network devices send log lines |
| networksyslog | The Splunk index (and likely Dynatrace bucket) holding network device logs |
| Static threshold | An alert that fires when a value goes above a fixed number |
| Sliding window | How many recent minutes are checked |
| Violating samples | How many of those minutes must break the threshold |
| Dealerting samples | How many clean minutes are needed before the problem closes |
| Counter metric | A metric that counts matching log lines as they arrive, cheaper than querying logs |
| Throttle | Splunk setting that stops repeat alerts for a while; off in this alert |
