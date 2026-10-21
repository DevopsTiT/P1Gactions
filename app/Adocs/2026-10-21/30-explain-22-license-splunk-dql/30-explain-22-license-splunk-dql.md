# Explain 22 License Splunk And DQL

```
What is query 22 asking?
 → Find ESB license log lines
 → Read the Expiration Date text
 → Turn that text into a real time (JST)
 → Keep only licenses that expire before now + 100 days
 → Show those rows (soonest first in DQL)
```

| Key point | Detail |
|---|---|
| What this is | An early-warning search for ESB licenses that will expire soon |
| Why it matters | If the license dies, ESB features can stop working |
| 100 days | “Soon” window — still time to renew before it breaks |

## Summary

Query **22** does not count traffic. It finds license-check log lines, extracts the expiration date, and keeps only rows where that date is sooner than 100 days from now. Splunk and DQL do the same job with different syntax.

## What the log looks like

```
Valid license key --> Evaluation = false, Expiration Date = Mon Dec 14 23:59:59 JST 2026, Contact Name = N/A, ...
```

| Piece of the line | Meaning |
|---|---|
| `Valid license key` | License check passed the “valid key” path |
| `Evaluation = false` | Not an evaluation / trial key |
| `Expiration Date = ...` | When the key stops being valid |
| `JST` | Japan time (UTC+9) |
| `, Contact Name = ...` | Extra text after the date (ignore for the date parse) |

---

## Splunk (item 22) — line by line

```
index="esbv4" "license"
| rex "Valid license key --> Evaluation = false, Expiration Date = (?<expiration_date>[^\n]+)"
| eval expiration_epoch = strptime(expiration_date, "%a %b %d %T JST %Y")
| where expiration_epoch < relative_time(now(), "+100d")
```

| Line | Plain English | Why you care |
|---|---|---|
| `index="esbv4" "license"` | Search the esbv4 log index; keep events that contain the word license | Narrows to the right app’s logs |
| `rex "... Expiration Date = (?<expiration_date>[^\n]+)"` | Use regex to cut the date text into a field named `expiration_date` | Splunk cannot compare dates until the date is its own field |
| `eval expiration_epoch = strptime(...)` | Turn that text into a Unix time using format `Day Mon dd HH:mm:ss JST Year` | Text like `Mon Dec 14...` is not sortable as a clock until converted |
| `where expiration_epoch < relative_time(now(), "+100d")` | Keep rows where expiration is **before** “now + 100 days” | That means “expires within the next 100 days” (or already expired) |

### Splunk time words

| Term | What it means |
|---|---|
| `strptime` | “String parse time” — text → timestamp |
| `%a %b %d %T JST %Y` | Weekday, month name, day, time, the letters JST, year |
| `relative_time(now(), "+100d")` | A clock time 100 days in the future from now |
| `expiration_epoch < that` | Expiration is sooner than that future point |

---

## DQL — same story

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

| Step | Plain English | Splunk twin |
|---|---|---|
| `fetch logs, from:now()-7d` | Look at logs from the last 7 days | Time picker / default search window |
| `filter ... esbv4` | Keep hosts / namespaces / pods related to esbv4 | `index="esbv4"` |
| `filter contains(... Expiration Date = )` | Keep the license-check line shape | `"license"` + rex pattern |
| `substring` after label | Cut text after `Expiration Date = ` | `rex` capture group |
| Cut at first `,` | Drop `, Contact Name = ...` so parse stays clean | Splunk `strptime` often stops at the date; DQL needs a clean string |
| `replaceString(... " JST " ...)` | Remove the letters `JST` | Format string already expected `JST` |
| `parse ... TIMESTAMP(...)` | Turn cleaned text into a time value | `strptime` |
| `- 9h` | Adjust because parse treated numbers as UTC, but log was JST | Splunk format included `JST` |
| `expiration_epoch < now() + 100d` | Same “within 100 days” rule | `relative_time(now(), "+100d")` |
| `sort ... asc` | Soonest expiry first | (optional in Splunk) |

### Why DQL uses `- 9h`

| Idea | Explanation |
|---|---|
| Log says JST | The wall clock in the log is Japan time |
| DQL `TIMESTAMP` with no zone | Dynatrace reads `Mon Dec 14 23:59:59` as if it were UTC |
| Subtract 9 hours | Move that instant back so it matches real JST |

Analogy: the log wrote “11pm in Tokyo.” If you pretend that was “11pm in London (UTC),” you are 9 hours wrong — so you subtract 9 hours to fix it.

---

## Happy path vs common mistakes

| Path | What you see |
|---|---|
| Happy path | Rows with `expiration_date` filled and `expiration_epoch` before now+100d |
| Date far away (e.g. May 2027 in Oct 2026) | 0 rows — filter correctly drops “not soon” |
| Contact Name left on the date string | Parse fails or wrong time — cut at `,` |
| Forgot `- 9h` | Expiry looks 9 hours off |

---

## Data flow map

```
esbv4 logs
  → keep license check line
  → cut "Expiration Date = ..." text
  → (DQL) stop at first comma
  → (DQL) remove " JST "
  → parse to real time (+ JST fix in DQL)
  → keep if time < now + 100 days
  → show / sort
```

## Related files

| File | Role |
|---|---|
| `29-transform-22-esbv4-license-dql/` | Full live + verify DQL |
| `30.sh` | Dual-write copy commands |

## Commands

See [30.sh](30.sh).
