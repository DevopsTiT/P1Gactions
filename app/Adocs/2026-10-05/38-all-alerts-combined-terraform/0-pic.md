# All Alerts Combined Picture

## Decision Tree

```
One file for all of today?
 seq folders already applied? → yes → state mv / import first
                              → no  → set 2 TF_VAR PagerDuty keys → init → validate → plan
 duplicate resource error?    → remove other seq .tf from the folder
 lookup error?                → upload Control-M and Jenkins lookups
 seq 35 silent?               → arrayMovingMax line present? (fixed in 38)
```

## Data Flow

```
seq 5–20 + seq 22 + seq 26 + seq 27–36 (latest versions)
  → joined, one provider block, seq 35 fixed
  → 38 combined .tf → plan → detectors + workflows
```
