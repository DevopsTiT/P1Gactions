# Investigation

| Input | Used for |
|---|---|
| v5 workflow (seq 8) | Tasks 1 to 3, unchanged |
| INC30340215 form | Payload fields in task 3 |
| QA Platforms form | Default set in task 2 |
| Seq 27 OPEN and CLOSE | Sync keys: correlation_id and dedup_key |
| Known risk: duplicate incidents | Task 4 now checks for an open incident first |
| Known risk: manual Run posting a fake ticket | Task 4 skips sample events unless ALLOW_SAMPLE_POST is true |
