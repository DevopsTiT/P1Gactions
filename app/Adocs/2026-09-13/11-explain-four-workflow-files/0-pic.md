# Explain Four Workflow Files — Pic

```
4 files = 2 workflows × 2 formats
  │
  ├─ OPEN  → YAML template + JSON twin (4 tasks)
  └─ CLOSE → YAML template + JSON twin (1 task)

OPEN:
  prepare → [SNOW create || PD trigger] → cross-link

CLOSE:
  resolve-snow-and-pd (find INC + resolve INC + resolve PD)
```
