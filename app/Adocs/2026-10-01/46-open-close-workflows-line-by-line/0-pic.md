# Open And Close Pic

```
OPEN (problem CREATED)                         CLOSE (problem CLOSED)
1 extract-event-tags      (0,1)                1 prepare-close          (0,1)
2 resolve-snow-values     (0,2)                ├─ 2a close-silva-incident (0,2)
3 build-payload           (0,3)                └─ 2b close-pagerduty      (1,2)
├─ 4a preview-silva (0,4) → 5a post-silva (0,5)
└─ 4b preview-pd    (1,4) → 5b trigger-pd (1,5)

Link between them:
  SILVA     correlation_id = P-261090
  PagerDuty dedup_key      = dt-problem-P-261090
```

```
OPEN gates: decision → preview problems/ready → sample → duplicate → DRY_RUN → send
CLOSE gates: is_closed → already Resolved → sample → DRY_RUN → send → verify state
```
