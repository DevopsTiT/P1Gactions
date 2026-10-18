# Pic

```
Splunk host + keywords + matched_keywords
  → DQL fetch logs
  → filter host.name + matchesPhrase(content)
  → fieldsAdd matched_keywords + time
  → fields …
```
