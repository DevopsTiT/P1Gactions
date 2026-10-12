# Cisco VPN LDAP Explained Glossary

| Term | What it means |
|---|---|
| Cisco ASA | Cisco firewall that also runs the VPN. |
| LDAP | How the VPN checks logins against Windows Active Directory. |
| Syslog | Standard way devices send log lines to a collector. |
| Splunk index | Named storage bucket for logs in Splunk. |
| sourcetype | Splunk label for a log format. |
| Cron expression | Five-part timer. `*/1 * * * *` means every minute. |
| Expires | How long Splunk keeps a fired alert in its list. |
| Throttle | Quiet period after an alert fires. |
| Records detector | Dynatrace DQL query run every minute that opens a problem when rows return. |
| Identity field | Field deciding whether a row joins an existing problem. |
| Workflow | Dynatrace automation that pages or emails when a problem opens. |
| Terraform provider | Plugin that lets Terraform talk to a service like Dynatrace. |
