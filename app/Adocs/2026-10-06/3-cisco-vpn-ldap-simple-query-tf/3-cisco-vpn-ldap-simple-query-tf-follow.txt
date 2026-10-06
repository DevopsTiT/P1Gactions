# Cisco VPN LDAP Simple Query

## Decision Tree

```
Detector query = your 3 lines
 + makeTimeseries at the end? → required (detectors only accept a time series)
 Notebook search → use the 3 lines alone (check.dql query 1)
 no alert on real failures? → threshold "3" too high → set "0"
```

## Short Takeaway

| Question | Answer |
|---|---|
| Filter lines | Exactly your 3 lines |
| Extra line | `makeTimeseries ... interval:1m`, needed by the detector |
| `%ASA-2-113022` filter | Removed |
| Threshold | "3" like Splunk; "0" recommended |

## Summary

The detector query now uses your filter as written. The only addition is the `makeTimeseries` line, which turns matching lines into a count per minute. The detector compares that count with the threshold every minute. For a manual search in a Notebook, use the three lines alone.

## Query

```
fetch logs
| filter contains(log.source, "/var/log/ASA/") or matchesValue(host.name, "ljcmgt14*")
| filter contains(content, "Windows_LDAP as FAILED")
| makeTimeseries count = count(default: 0), interval:1m
```

| Line | What it does |
|---|---|
| `fetch logs` | Reads logs from Grail |
| First filter | Keeps lines from the ASA log path or the ljcmgt14 host |
| Second filter | Keeps only "Windows_LDAP as FAILED" lines |
| `makeTimeseries` | Counts matching lines per minute, which the detector needs |

## Data Flow

```
ASA → ljcmgt14 → Grail → your 3 filter lines → count per minute → over threshold? → critical problem → page
```

## Investigation

| Checked | Finding |
|---|---|
| Detector input | Needs a time series result |
| Your query | Returns log rows, which suits a Notebook but not a detector on its own |

## Result

| Step | What to do |
|---|---|
| 1 | Run check.dql query 1 in a Notebook to see the lines |
| 2 | `terraform plan` shows 1 to add |
| 3 | Don't apply together with seq 1 or seq 2 (same resource name) |

## Related Files

| File | Purpose |
|---|---|
| `3-cisco-vpn-ldap-simple-query-tf.tf` | Detector Terraform |
| `3-cisco-vpn-ldap-simple-query-tf-check.dql` | Check queries |
| `3.sh` | Commands |
