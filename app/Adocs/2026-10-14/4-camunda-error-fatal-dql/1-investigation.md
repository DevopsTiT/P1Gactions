# Camunda Error Fatal DQL Investigation

| Splunk stage | DQL step |
|---|---|
| sourcetype="camunda-platform" | Dropped, host prefixes enough |
| host identity, zeebe, zeebe-gateway, keycloak | 3 startsWith prefixes on host.name and k8s.pod.name |
| search ("ERROR" OR "FATAL") | contains, case sensitive |
| mvappend(if(match(...))) | arrayRemoveNulls(array(if(contains(...)))) |
| where isnotnull(matched_keywords) | Not needed |
| strftime | formatTimestamp, Asia/Tokyo |
| table | fields |
| Unknown | Whether camunda8 logs are in Dynatrace, and under which field |
