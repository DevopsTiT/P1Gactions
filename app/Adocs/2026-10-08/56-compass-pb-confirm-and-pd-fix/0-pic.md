# CompassPB and PD Fix Pic

```
CompassPB = seq 23 → fixed seq 27 → no change (pagerduty 1)
AG Portal NTTGW seq 52 = seq 27 but pagerduty 0 → don't apply 52
Banca Portal seq 53 = seq 27 but pagerduty 0 → don't apply 53
→ apply seq 56 (three seq 27 detectors) from ONE folder
```
