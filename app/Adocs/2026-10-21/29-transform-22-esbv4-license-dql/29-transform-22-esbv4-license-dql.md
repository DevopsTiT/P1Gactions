# Transform 22 ESBv4 License DQL

```
esbv4 "license" line?
 → keep "Valid license key --> Evaluation = false, Expiration Date = "
 → cut text after "Expiration Date = " (stop at first "," if Contact Name follows)
 → strip " JST " → parse as TIMESTAMP → treat as UTC then -9h (JST)
 → keep if expiration < now() + 100d
 → sort soonest first
```

| Key point | Detail |
|---|---|
| What this is | Find ESB license lines that expire within the next 100 days |
| Why it matters | You want warning before the key dies, not after |
| Splunk `+100d` | Same idea as DQL `now() + 100d` |

## Summary

Splunk item **22** pulls the expiration date from the license log line, turns JST text into a real time, and keeps rows where that time is still before “today + 100 days”. The DQL below matches that logic and also trims trailing `, Contact Name = …` so parse does not break.

## Splunk (source)

```
index="esbv4" "license"
| rex "Valid license key --> Evaluation = false, Expiration Date = (?<expiration_date>[^\n]+)"
| eval expiration_epoch = strptime(expiration_date, "%a %b %d %T JST %Y")
| where expiration_epoch < relative_time(now(), "+100d")
```

## DQL (live)

```
fetch logs, from:now()-7d
| filter contains(host.name, "esbv4", caseSensitive:false)
    or contains(k8s.namespace.name, "esbv4", caseSensitive:false)
    or contains(k8s.pod.name, "esbv4", caseSensitive:false)
| filter contains(content, "Valid license key --> Evaluation = false, Expiration Date = ")
| fieldsAdd after_label = trim(substring(content, from:indexOf(content, "Expiration Date = ") + 18))
| fieldsAdd expiration_date = if(contains(after_label, ","),
      trim(substring(after_label, from:0, to:indexOf(after_label, ","))),
      after_label)
| fieldsAdd exp_clean = replaceString(expiration_date, " JST ", " ")
| parse exp_clean, "TIMESTAMP('EEE MMM dd HH:mm:ss yyyy'):exp_as_utc"
| fieldsAdd expiration_epoch = exp_as_utc - 9h
| filter expiration_epoch < now() + 100d
| sort expiration_epoch asc
| fields timestamp, host.name, expiration_date, expiration_epoch, content
```

## Verify dummy (fieldsAdd)

Use a date **inside** 100 days so the filter returns a row. Sample style matches your log (with Contact Name).

```
fetch logs
| fieldsAdd dummy = "2026-10-15 09:12:34,567 INFO [LicenseCheck] Valid license key --> Evaluation = false, Expiration Date = Mon Dec 14 23:59:59 JST 2026, Contact Name = N/A, Contact Email Address = N/A"
| fields dummy
| filter contains(dummy, "Valid license key --> Evaluation = false, Expiration Date = ")
| fieldsAdd after_label = trim(substring(dummy, from:indexOf(dummy, "Expiration Date = ") + 18))
| fieldsAdd expiration_date = if(contains(after_label, ","),
      trim(substring(after_label, from:0, to:indexOf(after_label, ","))),
      after_label)
| fieldsAdd exp_clean = replaceString(expiration_date, " JST ", " ")
| parse exp_clean, "TIMESTAMP('EEE MMM dd HH:mm:ss yyyy'):exp_as_utc"
| fieldsAdd expiration_epoch = exp_as_utc - 9h
| filter expiration_epoch < now() + 100d
| fields expiration_date, expiration_epoch, dummy
```

**Pass:** `expiration_date = Mon Dec 14 23:59:59 JST 2026` (no Contact Name stuck on the field).

**Note:** Your sample `Tue May 18 08:59:59 JST 2027` is more than 100 days from late Oct 2026, so live filter correctly drops it until you are inside that window.

## Splunk → DQL map

| Splunk | What it means | DQL |
|---|---|---|
| `index="esbv4" "license"` | Logs from esbv4 that mention license | host / namespace / pod contains `esbv4`, then license phrase |
| `rex ... Expiration Date = (?<expiration_date>...)` | Cut the date text | `substring` after label; stop at `,` |
| `strptime(..., "%a %b %d %T JST %Y")` | Text → time in JST | remove ` JST `, parse, then `- 9h` |
| `where ... < relative_time(now(), "+100d")` | Expires before now+100d | `expiration_epoch < now() + 100d` |

## Why `- 9h`

| Step | What happens |
|---|---|
| Log says `JST` | Clock in Japan (UTC+9) |
| `TIMESTAMP(...)` with no zone | Dynatrace reads the numbers as UTC |
| `- 9h` | Shift those numbers back so the instant matches real JST |

## Data flow map

```
content / dummy
  → must contain "Valid license key --> ... Expiration Date = "
  → after_label = text after "Expiration Date = "
  → expiration_date = cut at first ","
  → exp_clean = drop " JST "
  → parse TIMESTAMP → exp_as_utc
  → expiration_epoch = exp_as_utc - 9h
  → keep if expiration_epoch < now() + 100d
  → sort asc → fields
```

## Related files

| File | Role |
|---|---|
| `29-transform-22-esbv4-license-dql.dql` | Live + verify |
| `29.sh` | Dual-write to Adocs |
| `14-verify-dql-1-to-85-dummy/` | Earlier #22 verify (data record style) |
| `2026-10-14/13-portals-pc-ui-esbv4-license-dql/` | Original #20–#31 pack |

## Commands

See [29.sh](29.sh).
