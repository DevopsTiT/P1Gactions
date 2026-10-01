# Glossary

| Term | What it means | Why you care |
|---|---|---|
| `contains(a, b, caseSensitive: false)` | Text `a` includes `b`, ignoring case | Same check as your query |
| `coalesce(x, y, ...)` | Returns the first value that is not null | Picks which pic2 item a file matches |
| `if(cond, value)` | Returns value when true, null otherwise | Each item's test inside coalesce |
| `append [data record(...)]` | Adds hand-written rows | Makes NO rows visible |
| `countIf(cond)` | Counts rows where the condition is true | Used in Q2 and Q3 |
| `collectDistinct` | Unique list of values | Shows the real file names per item |
| Code 1 / 0 | Numeric YES / NO | Easy to sum or filter |
