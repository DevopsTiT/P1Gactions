# Combined Terraform Picture

## Decision Tree

```
One file for everything?
 already applied seq folders? → yes → state mv / import first (or keep seq folders)
                              → no  → init → validate → plan (21 to add) → apply
 duplicate resource error?    → a seq .tf sits in the same folder → remove it
 lookup error?                → upload /lookups/controlm/* and /lookups/jenkins/configuration
```

## Data Flow

```
seq 27, 28, 29, 31, 32, 34, 35, 36 .tf
  → joined, one provider block
  → 37 combined .tf
  → plan: 14 detectors + 7 workflows
```
