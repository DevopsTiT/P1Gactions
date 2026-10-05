# PowerCenter Down Alerts Picture

```
3 Splunk alerts (same search)
 > 0 in 15 min (High)  ─┐
 > 2 in 1 min (Normal) ─┼→ "> 0" covers the others → 1 detector
 > 3 in 1 min (Normal) ─┘

lines rare?        → threshold "0"
lines constant?    → threshold "2"
```

```
PowerCenter log → Grail → detector (per minute, per host)
 → count > 0 → problem (High) → standard flow → SILVA + PagerDuty
 → 15 quiet minutes → close
```
