# Functions And Traces Pic

```
OPEN
 1 main → ex.event → getProblem [DT API] → parseTag, allByKey, findByKey, envLabel
 2 main → groupByName, serviceByName, serviceById, findCis, servicesForCi → getRows [SILVA GET x N] → score, active
 3 main → bodies (no API)
 4a main → fetch GET incident [SILVA]      4b main → checks (no API)
 5a main → fetch GET + POST incident [SILVA]  5b main → fetch POST enqueue [PD]

CLOSE
 1 main → ex.event → getProblem [DT API] → toMs, duration
 2a main → choiceValue/softChoice → getRows sys_choice x5 → getRows incident → patch x1..3 [SILVA]
 2b main → fetch POST enqueue resolve [PD]

Real traces: Execution → task Result/Log | task2 steps | 2a attempts | sys_audit | PD log_entries
```
