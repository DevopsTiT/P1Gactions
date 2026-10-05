# Control-M Alerts Picture

```
9 Splunk alerts
 daily table (CHDE010M x2, CHDR010M, PDDW0100) → 1 for_each workflow (4 reports)
 Ended not OK now (V1, V2)                    → 1 detector, per job_name
 per-job result email + contact CC             → workflow with loop
 abend then rerun OK                           → workflow (overlaps the one above)
 claims job running 15+ min                    → workflow every 5 min, once per run
```

```
Control-M → Grail
  alert events → detector → problem → standard flow
  activejobs   → workflows → email
  CSVs         → /lookups/controlm/* → lookup by job_name
```
