# Investigation

| What was checked | Finding |
|---|---|
| Seq 36 OPEN YAML | Trigger, task 1 tag parsing, task 2 lookup order, task 3 fields and decision, previews and send gates. |
| Seq 37 CLOSE YAML | Trigger on close, choice-list checks, preview gates, PATCH and state verification. |
| Seq 39 CLOSE direct | Same keys, 3 tasks, resolves all open incidents. |
| Shared keys | correlation_id = display id; dedup_key = dt-problem-<display id>. |
| P-261090 run (seq 35) | Used as the worked example. |
