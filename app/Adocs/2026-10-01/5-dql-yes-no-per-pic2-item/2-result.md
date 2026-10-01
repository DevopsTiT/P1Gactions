# Result

| Step | What to do | Expected |
|---|---|---|
| 1 | Run Q3 | CalcServer.log → YES, proves the method |
| 2 | Run Q1 with Last 7 days | 23 rows, each YES or NO with code 1 or 0 |
| 3 | For YES rows | `sources` shows the real file names |
| 4 | For NO rows | File not ingested in this host group: check the file exists, then the log ingest rule |
