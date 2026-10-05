# Glossary

| Term | What it means |
|---|---|
| TypeError "Cannot read properties of undefined" | A Node.js error when code reads a field from a missing object |
| OCP | OpenShift Container Platform, Red Hat's Kubernetes distribution |
| Namespace | A named area in Kubernetes that holds one app's pods |
| Pod | One running copy of an app container |
| timechart span=1m | Splunk command that counts events per minute |
| For each result | Splunk sends one action per result row |
| Throttle | Splunk setting that suppresses repeat alerts for a time |
| Static-threshold detector | Dynatrace rule that fires when a value crosses a fixed number |
| violatingSamples | How many bad minutes in the window open a problem |
| slidingWindow | How many recent minutes the detector looks at |
| dealertingSamples | How many good minutes close the problem |
| makeTimeseries | DQL command that turns log lines into a per-minute series |
| app.name | Event property used to route problems that have no host |
