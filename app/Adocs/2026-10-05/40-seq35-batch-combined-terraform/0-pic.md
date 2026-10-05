# Seq 35 Batch Picture

## Decision Tree

```
Which batches?
 seq 35 only       → batch-35/ (3 detectors)
 seq 34 + 35 + 36  → all-34-35-36/ (4 detectors)  ← recommended
 two files in one folder → duplicate resource error
 already applied old seq folders → move state first
```

## Data Flow

```
URL checks        → URL detector        ┐
AGGW LB timing    → Outlier detector    ┤
Functional tests  → Functional detector ┼→ problems → standard flow
Broker pod logs   → Broker detector     ┘
```
