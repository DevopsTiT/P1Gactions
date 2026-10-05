# Control-M Alerts V2 Picture

```
13 Splunk alerts
 _test or 複製            → skip (3)
 only writes a CSV        → skip (リラン確認)
 same job + list + time   → merge (CHDE010M 11:30 x2)
 rest                     → 1 detector + 6 workflows
```

```
Control-M → Grail
  abend   → detector → standard flow
  reports → 4 daily emails
  notify  → per-job email
  overrun → once per stuck run
```
