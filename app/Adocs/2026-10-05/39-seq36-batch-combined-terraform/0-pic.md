# Seq 36 Batch Picture

## Decision Tree

```
seq 36 screenshots → one .tf
 seq 34 / 36 already applied? → yes → move state or keep old folders
                              → no  → upload Jenkins lookup → plan (3 to add) → apply
 no data in a detector?       → run its check.dql and fix the filter
```

## Data Flow

```
Jenkins console → URL detector        ┐
Jenkins tests   → Functional detector ┼→ problems → standard flow
Broker pod logs → Broker detector     ┘
```
