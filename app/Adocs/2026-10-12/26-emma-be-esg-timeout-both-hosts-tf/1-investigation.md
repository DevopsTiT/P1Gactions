# Emma BE ESG Timeout Both Hosts Investigation

| What was checked | Finding |
|---|---|
| Search | `index="apigw_syslog" sourcetype=apigw_syslog_prod` |
| Hosts | 1: EEAA2015.ppprivmgmt.intraxa |
| Sources | 1: /SYSLOG/APIGW/prod/local4.log |
| Volume | 315,104 events in about 24 hours |
| Line format | `epago30100 SSG[...]: [] INFO com.l7tech...` |
| Backend hosts (answer 25) | 17 pod names starting with myaxabackend- |
