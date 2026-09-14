# Result

The diagram is one Problem lifecycle: open runs the create workflow (prepare, create INC, page PD, cross-link); close runs the close workflow (resolve INC + PD). Shared Problem ID links them via `correlation_id` and `dedup_key`. Dynatrace drives both systems.

| Half | One sentence |
| --- | --- |
| Open | Make ticket + page and stamp both with Problem ID |
| Close | Find by that stamp and close both |
