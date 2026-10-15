# Splunk To DQL Investigation

The rules come from converting Splunk queries #1 to #85 (answers 15 and 16 of 2026-10-15).

| Splunk habit | DQL behavior | What to do |
|---|---|---|
| Search terms ignore case | `contains` is case-sensitive | Use `matchesPhrase` or `caseSensitive:false`. |
| `key=value` becomes a field automatically | No automatic field | Add `parse` first. |
| Subsearch pastes results as words | No text pasting | Parse the key on both sides and use `lookup`. |
| `index` picks the data | No index field | Filter on pod, host or log source. |
| `substr` counts from 1 | `substring` counts from 0 | Subtract 1 from the start. |
| Wildcards with `*` | `contains` and `startsWith` need no stars | Drop the stars. |
