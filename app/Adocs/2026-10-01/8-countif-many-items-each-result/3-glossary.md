# Glossary

| Term | What it means | Why you care |
|---|---|---|
| `countIf(cond)` | Counts log lines where the condition is true | One count per item |
| `record(a = x, b = y)` | Makes a small object with named fields | Pairs item name with its count |
| `array(...)` | A list of values | Holds all item records |
| `expand` | One row per list element | Turns the list into rows |
| `fieldsFlatten` | Turns `items.item` into a normal column | Readable table |
| `sum(if(cond, n, else: 0))` | Adds counts only for matching rows | Used in the lighter query C |
| Scanned bytes | How much log data the query read | Main cost driver |
