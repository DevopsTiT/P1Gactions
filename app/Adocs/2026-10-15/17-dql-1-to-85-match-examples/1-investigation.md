# DQL Match Examples Investigation

Each sample was checked by hand against the DQL in answer 16. No query was run in Dynatrace.

| Query | What to confirm with a real log |
|---|---|
| #13, #16, #33, #40, #45, #46, #57 | How `matchesPhrase` splits words around dots, underscores and `=`. |
| #22 | The time zone used when reading the expiry date. |
| #41, #47 | That `LD` before `','` stops at the first comma. |
| #65 | That the class name capture comes out in full. |
| #67 | That `INT` reads the date parts as positive numbers. |
| #81 | Whether `toLong` drops or rounds the fraction of days. |
