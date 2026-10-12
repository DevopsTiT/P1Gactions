# Process Network Charts Pic

```
Y   requests, one instance, 3 days     → steady base + spikes
Z   bytes_rx × 8, one instance, 2 h    → bits not bytes; three bursts
AA  group filter, split by instance    → 2 instances (correct pattern)
BB  INSTANCE ID on GROUP field         → 0 records
CC  requests, quiet instance           → idle with bursts

PROCESS_GROUP-          → dt.entity.process_group
PROCESS_GROUP_INSTANCE- → dt.entity.process_group_instance
```
