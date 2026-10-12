# Control-M Abend Alert V2 Pic

## Decision tree

```
"Ended not OK" in last 5 min
 parse fields → job_name empty? → fix parse (check query 1, 3)
 build JOB_CODE → one problem per abend (high) → email
 need owner and cmd_line? → check query 4 join
```

## Data flow

```
Control-M abend → alert line → Grail → detector (5 min, parse, fieldsAdd) → problem per JOB_CODE → workflow → email
```
