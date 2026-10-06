# Glossary

| Term | What it means |
|---|---|
| Log event | Dynatrace rule that raises an event whenever a log line matches a matcher |
| Matcher | Simple log filter such as `matchesPhrase(content, "...")`; not a full DQL query |
| makeTimeseries | DQL command that turns log lines into counts per time bucket; detectors need it |
| matchesPhrase | True when the text contains that exact phrase |
| matchesValue | True when a field equals a value; `*` is a wildcard |
| CUSTOM_ALERT | Event type that opens a Dynatrace problem and can trigger notifications |
