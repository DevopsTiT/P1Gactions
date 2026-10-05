# Broker Policy Alert Picture

## Decision Tree

```
Screenshot alert name
 in seq 34 list? → yes → skip (already converted)
 Broker Policy "Cannot read properties of undefined"
   count per minute > 50 → static-threshold detector
   query 1 finds logs by namespace? → yes → apply
                                    → no  → fix first filter
   too noisy in query 3? → raise threshold or violating 2 of 5
```

## Data Flow

```
OCP pods → logs → Grail
  → count per minute → > 50 ?
  → yes → one problem → standard flow → email / SILVA
  → 5 quiet minutes → close
```
