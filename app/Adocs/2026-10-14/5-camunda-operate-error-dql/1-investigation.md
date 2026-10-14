# Camunda Operate Error DQL Investigation

| Splunk stage | DQL step |
|---|---|
| sourcetype="camunda-platform" | Dropped |
| host="camunda8-prod-operate-*" | startsWith on host.name or k8s.pod.name |
| search "ERROR" + regex _raw="ERROR" | contains(content, "ERROR"), case sensitive |
| strftime | formatTimestamp, Asia/Tokyo |
| table time host _raw | fields time, host.name, k8s.pod.name, content |
