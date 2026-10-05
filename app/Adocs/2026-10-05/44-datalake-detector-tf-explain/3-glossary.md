# Glossary

| Term | What it means |
|---|---|
| Provider | Terraform plugin that knows how to talk to a service (here Dynatrace) |
| Resource | One thing Terraform creates and manages |
| Davis anomaly detector | Dynatrace custom alert that runs a query every minute |
| Static threshold | Fixed limit the value is compared against |
| Grail | Dynatrace storage for logs and other data |
| makeTimeseries | DQL command that turns log lines into a number per time slot |
| slidingWindow | How many recent minutes the rule looks at |
| violatingSamples | Bad minutes needed to open a problem |
| dealertingSamples | Good minutes in a row needed to close it |
| Problem | Dynatrace incident record that triggers notifications |
| Event template | Properties attached to the problem (title, severity, routing hints) |
