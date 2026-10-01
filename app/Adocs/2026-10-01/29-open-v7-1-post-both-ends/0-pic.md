# OPEN v7.1 Picture

```
problem → 1 → 2 → 3 (decision)
  skip? (maintenance, missing, sample) → both skipped
  create ─┬→ 4a SILVA: GET dup → exists | POST → INC
          └→ 4b PD: POST enqueue → triggered (dedup_key)
```
