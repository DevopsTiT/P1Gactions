# IWFM Alerts Picture

```
EIP006 FAILURE > 2 / 1 min        → detector, threshold 2 (high)
IWFMReportException > 15 / 5 min  → detector, moving sum 5, threshold 15 (medium)
IWFM agent Caution or Fatal       → detector, threshold 0, dealerting 60 (medium)
```

```
logs → Grail → detector → problem → standard flow → SILVA + PagerDuty
```
