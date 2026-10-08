# Broker Policy Maintenance Glossary

| Term | What it means | Why you care |
|---|---|---|
| dc(host) | Splunk distinct count of hosts | Counts how many pods sent logs |
| countDistinct | Dynatrace version of dc | Same count in DQL |
| Pod | One running copy of the app in Kubernetes | Here each pod shows up as one "host" |
| Replica count | How many pods the deployment keeps running | The threshold of 2 assumes 2 replicas |
| Log forwarder | Process that ships logs to S3 or Splunk | If it stops, the count drops even though pods are fine |
