# Datalake Batch Result Detector Picture

## Decision Tree

```
alert only → detector, any line → problem
 every run alerts? → add failure filter (check.dql 4)
 no data?          → fix log.source (check.dql 1)
 workflow applied? → remove seq 29 / 42
```

## Data Flow

```
batch lines → Grail → detector each minute → problem → standard flow
60 quiet minutes → close
```
