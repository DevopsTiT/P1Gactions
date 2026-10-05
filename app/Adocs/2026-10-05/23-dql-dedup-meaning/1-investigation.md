# Investigation

| What was checked | Finding |
|---|---|
| Question | Meaning of `dedup timestamp, content` in the LDAP alert |
| Why it was added | Same ASA line may arrive through two syslog paths |
| Effect without it | Count doubles, threshold 3 is crossed by 2 real failures |
| Splunk equivalent | `dedup _time _raw` |
