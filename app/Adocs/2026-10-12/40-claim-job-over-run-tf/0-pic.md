# Claim Job Over Run Pic

## Decision tree

```
claims job in daily_ctmag log, last 24 h
 STARTED line? no → ignore
 ENDED line after it? yes → fine
 no, and 15+ min since start → problem medium per job → email
 job list empty? → fill claims_jobs from Splunk lookup
```

## Data flow

```
Control-M agent → daily_ctmag log → Grail → detector (start vs end per run) → problem per job → workflow → email
```
