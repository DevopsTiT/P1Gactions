# Ebroker SSL Cert 81 Explained

## Decision tree

```
Goal: warn before the ebroker HTTPS certificate expires (30 days ahead)
 Splunk #81: makes one row for ebroker → looks up its end date in sslcert_lookup → keep if < now + 30d
 Dynatrace has sslcert_lookup? 
  no (default) → Option B: Synthetic HTTP monitor with certificate expiry check (recommended)
  someone uploads it to Grail → Option A: load the lookup file → same filter
 Result row returned? → cert expires within 30 days → renew it
 No row → cert is fine for at least 30 days (or the table is stale)
```

## Short takeaway

| Question | Answer |
|---|---|
| What does #81 check? | Whether the SSL certificate of the ebroker server expires within 30 days. |
| Does it read logs? | No. It reads a Splunk lookup table (a stored CSV) called `sslcert_lookup`. |
| Why is it hard in Dynatrace? | Dynatrace has no copy of that table, so there is nothing to query by default. |
| Best Dynatrace answer | A Synthetic HTTP monitor that checks the certificate itself and raises a problem when fewer than 30 days remain. |

## Summary

#81 is not a log search. It asks a stored table "when does the ebroker certificate end?" and returns a row only if that date is less than 30 days away. Dynatrace can copy this with a Grail lookup file, but a Synthetic monitor is better because it checks the real certificate instead of a table someone must keep updated.

## Investigation

### Words you need first

| Word | What it means |
|---|---|
| SSL/TLS certificate | The file a server uses to prove its identity for HTTPS. It has an end date. |
| Certificate expiry | When the end date passes, browsers and API clients refuse to connect. |
| Lookup table | A CSV stored in Splunk that searches can read like a small database. |
| `makeresults` | Splunk command that creates one empty row so you can add fields to it. |
| `relative_time(now(), "+30d")` | Splunk for "the time 30 days from now". |
| Grail lookup file | A CSV uploaded into Dynatrace Grail that DQL can read with `load`. |
| Synthetic HTTP monitor | A Dynatrace robot that calls a URL on a schedule and checks the response and certificate. |

### The Splunk search (rebuilt from the mapping)

The original screenshot is not in my notes, so this is rebuilt from the pieces mapped in 2026-10-14 answer 17. Check it against your file.

```
| makeresults
| eval dest="ebroker-inssuite-prod.op-prod-lpl.axa-direct-jp.intraxa"
| lookup sslcert_lookup dest OUTPUT ssl_end_time
| where ssl_end_time < relative_time(now(), "+30d")
```

### Splunk line by line

| Line | What it does |
|---|---|
| `\| makeresults` | Starts with one empty row. No logs are read. |
| `eval dest="ebroker-inssuite-prod..."` | Puts the ebroker host name in the row. |
| `lookup sslcert_lookup dest OUTPUT ssl_end_time` | Finds that host in the table and copies its certificate end time (Unix seconds) into the row. |
| `where ssl_end_time < relative_time(now(), "+30d")` | Keeps the row only if the end time is before "now plus 30 days". |
| Result | One row means "renew soon". No row means "fine for now". |

### DQL Option A line by line (Grail lookup file)

| Line | What it does |
|---|---|
| `load "/lookups/sslcert_lookup"` | Reads the uploaded CSV. Replaces `makeresults` plus `lookup`. |
| `filter dest == "ebroker-inssuite-prod..."` | Keeps only the ebroker row. |
| `fieldsAdd ssl_end = timestampFromUnixSeconds(toLong(ssl_end_time))` | Turns the Unix seconds into a real timestamp. |
| `fieldsAdd days_left = ...` | Extra: how many days remain. |
| `filter ssl_end < now() + 30d` | Same as the Splunk `where`. |
| `fields dest, ssl_end, days_left` | Shows the result. |

### Option A compared with Option B

| | Option A: Grail lookup file | Option B: Synthetic monitor |
|---|---|---|
| Source of truth | A CSV someone must keep updated | The real certificate on the server |
| Setup | Upload the CSV, schedule the query | Create one monitor, turn on the certificate check |
| Alerting | Needs a workflow or saved query | Raises a Dynatrace problem automatically |
| Risk | Table goes stale and shows nothing | Monitor needs network access to the host |

## Result

Use Option B. Create a Synthetic HTTP monitor on `https://ebroker-inssuite-prod.op-prod-lpl.axa-direct-jp.intraxa`, turn on "certificate expires in less than 30 days", and let Dynatrace raise the problem. The ebroker host is internal (`.intraxa`), so the monitor must run from a private Synthetic location (ActiveGate) that can reach it.

Use Option A only if your team already maintains `sslcert_lookup` and wants the same table in Dynatrace. Queries are in `11-ebroker-ssl-cert-81-explained.dql`.

## Data flow map

```
Splunk #81
 makeresults → dest = ebroker host → sslcert_lookup (CSV) → ssl_end_time → < now + 30d → row or nothing

Dynatrace Option A
 load /lookups/sslcert_lookup (uploaded CSV) → filter dest → convert time → < now + 30d → row

Dynatrace Option B
 private Synthetic location → HTTPS call to ebroker → read certificate → < 30 days → Dynatrace problem → alert
```

## Related files

| File | Purpose |
|---|---|
| `11-ebroker-ssl-cert-81-explained.dql` | Option A query and an Option B problem check |
| `0-pic.md` | Decision tree and data flow |
| `1-investigation.md` | Line-by-line notes |
| `2-result.md` | Recommendation |
| `3-glossary.md` | Terms |
| `11.sh` | Git one-liners (not run) |

## Commands

See `11.sh`. None of these commands have been run.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-15/11-ebroker-ssl-cert-81-explained
git commit -m "ebroker ssl cert 81 explained"
git push
```
