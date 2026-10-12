# ActiveGate Entity And Process Network Load Pic

```
T, U   → repeat of answer 9
V      dt.entity.apm_security_gateway (ActiveGates) + "eastasia" tag filter → 0
         → no filter first (V0) → read tags (V1) → case-insensitive filter (V2)
         → health_status = entity.type is wrong
W      fetch logs → raw, unfocused → add range, columns, limit
X      network load, one process instance → works → daily waves, spike near Jun 25
```
