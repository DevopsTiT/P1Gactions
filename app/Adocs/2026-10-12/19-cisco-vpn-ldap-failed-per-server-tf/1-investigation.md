# Cisco VPN LDAP Per Server Investigation

| What was checked | Finding |
|---|---|
| Splunk result count | 2 events between 9/12/26 and 10/12/26. |
| Event text | `%ASA-2-113022: AAA Marking LDAP server 10.3.87.x in aaa-server group Windows_LDAP as FAILED` |
| Servers seen | 10.3.87.1 on Sep 23, 10.3.87.2 on Sep 24. |
| Host | ljcmgt14.ads-jp.intraxa |
| Source file | /var/log/ASA/JPNDH-VASA19-ALJ.log |
| Old threshold | More than 3 in 1 minute. Neither event would have fired it. |
| Secrets | None visible. Nothing copied. |
