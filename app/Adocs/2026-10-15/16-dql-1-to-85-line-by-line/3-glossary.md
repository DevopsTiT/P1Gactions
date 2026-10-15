# DQL 1 To 85 Glossary

| DQL term | What it means |
|---|---|
| `fetch logs, from:now()-24h` | Read logs from the last 24 hours. |
| `filter` | Keep rows where the condition is true. |
| `fieldsAdd` | Add a new column. |
| `lower()` | Make text lower case. |
| `coalesce(a, b)` | Use a, or b when a is empty. |
| `startsWith()` | Text begins with a prefix. |
| `endsWith()` | Text ends with a suffix. |
| `contains()` | Text includes a substring. |
| `caseSensitive:false` | Ignore upper and lower case in `contains`. |
| `matchesPhrase()` | Whole word or phrase, ignoring case. |
| `matchesValue()` | Value matches a pattern with `*`, ignoring case. |
| `in(x, array(...))` | x equals one of the listed values. |
| `arrayRemoveNulls(array(if(...)))` | Build a list of matched keywords. |
| `parse` | Extract fields with DPL patterns. |
| `LD` | DPL: any characters on the line. |
| `DIGIT`, `ALNUM`, `WORD`, `SPACE` | DPL character classes. |
| `JSON:j` | DPL: read text as JSON into field j. |
| `replaceString()` | Replace plain text. |
| `indexOf()` and `substring()` | Find a position and cut text. |
| `splitString()` and `expand` | Split text into a list, then one row per item. |
| `summarize ... by:{ }` | Group and calculate. |
| `count()`, `countIf()` | Count rows, or rows where a condition is true. |
| `countDistinctExact()` | Count unique values. |
| `collectDistinct()`, `collectArray()` | Gather values into a list. |
| `makeTimeseries` | Count per time bucket for a chart. |
| `timeseries` | Read metrics over time. |
| `lookup [ ], sourceField:, lookupField:, prefix:` | Join a second query on a shared field. |
| `isNotNull()` | The field has a value. |
| `dedup` | Keep one row per value. |
| `load "/lookups/..."` | Read an uploaded lookup file. |
| `formatTimestamp()` | Turn a time into readable text. |
| `sort ... desc` | Order rows, largest or newest first. |
| `fields` | Choose which columns to show. |
