# Pic — Workflow YAML Syntax

```
YAML rules: indent + keys + lists + | scripts
     │
     ▼
metadata (apps, connection targets)
workflow (title, trigger, tasks)
     │
     ▼
task: action, predecessors, conditions, input
     │
     ▼
{{ result("task").field }} at runtime
```
