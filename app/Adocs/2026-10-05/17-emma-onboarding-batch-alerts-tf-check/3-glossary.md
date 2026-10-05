# Glossary

| Term | What it means |
|---|---|
| `for_each` | Terraform loop that creates one resource per map entry |
| `each.value` | The current map entry inside a `for_each` block |
| `$name$` | Splunk token for the alert name; it means nothing in Dynatrace |
| `{{ event()["event.name"] }}` | Workflow expression for the problem name |
| `startsWith` | DQL function used to match all problems sharing a name prefix |
| False positive | An alert that fires on a harmless line |
