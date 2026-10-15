# Why 80 DQL Shape Investigation

| Splunk feature | DQL replacement | Reason |
|---|---|---|
| Subsearch | `lookup` | DQL cannot paste results as search text. |
| `format` with `query` | Field match | Splunk-only trick. |
| `index=esbv4` | `startsWith(src, "esbv4")` | No indexes in Dynatrace. |
| Raw-text ID match | Outer `parse` | `lookup` needs a field. |
| Case-insensitive phrase | `caseSensitive:false` | DQL `contains` is case-sensitive by default. |
| Implicit "only matches" | `filter isNotNull(err.query)` | `lookup` keeps unmatched rows. |
