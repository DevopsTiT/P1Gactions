# Glossary

| Term | What it means |
| --- | --- |
| `#` comment | Human note; not executed by Dynatrace |
| `>-` | YAML folded multi-line string |
| `\|` | YAML literal block (keeps newlines) — used for JS |
| `predecessors` | Tasks that must finish first |
| `conditions.states: OK` | Only run if named task succeeded |
| `ex.result("task-id")` | Read prior task output |
| `correlation_id` | SNOW sync field |
| `dedup_key` | PD sync field |
| Soft return | CLOSE returns found:false instead of throw |
