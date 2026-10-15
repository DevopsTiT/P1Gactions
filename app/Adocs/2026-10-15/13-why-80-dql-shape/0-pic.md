# Why 80 DQL Shape Pic

```
No subsearch in DQL → lookup (V1) or summarize by ID (V2)
No raw-text ID match → parse ID on both sides
No index → startsWith(src, "esbv4")
Splunk ignores case → caseSensitive:false
lookup keeps all rows → filter isNotNull(err.query)
```

```
V1: inner fetch (timeouts → IDs) + outer fetch (kakaku lines → ID) → join
V2: one fetch (both line types) → group by ID → both present
```
