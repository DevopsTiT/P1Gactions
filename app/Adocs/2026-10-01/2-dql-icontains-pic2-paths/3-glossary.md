# Glossary

| Term | What it means | Why you care |
|---|---|---|
| icontains | Case-insensitive contains | The check you asked for |
| `contains(a, b, caseSensitive: false)` | True when text `a` includes text `b`, ignoring case | Core of every query here |
| `array(...)` | A list value stored in one field | Holds the 23 pic2 paths |
| `pic2[]` | Each element of the array, inside an iterative function | Lets one expression check all paths |
| `iAny(...)` | True if the condition is true for any element | The yes/no answer |
| `iCollectArray(...)` | Builds a new array from each element's result | Shows which pic2 paths matched |
| `arrayRemoveNulls` | Drops empty entries from an array | Cleans the matched list |
| `expand` | Turns one row with an array into one row per element | Needed for the FOUND/MISSING table |
| `append [data record(...)]` | Adds hand-written rows | Makes unmatched pic2 paths visible |
| `log.source` | File path or log name of the log line | The field being checked |
