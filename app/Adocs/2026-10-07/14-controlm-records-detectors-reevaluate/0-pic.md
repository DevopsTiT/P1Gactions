# Control-M Records Detectors Pic

```
13 Splunk Control-M alerts
 ├─ abend V1 + V2           → job_abend (per job_name, high)
 ├─ ジョブ実行結果通知        → job_result_after_abend (per order_id)
 ├─ Claim Job Over Run      → claims_job_overrun (per order_id)
 ├─ 3 CHDE010M reports      → chde010m_no_success (74h)
 ├─ CHDR010M report         → chdr010m_no_success (26h)
 ├─ PDDW0100 report         → pddw_no_success (26h)
 └─ リラン確認, _test, 複製 x2 → not migrated
```

```
logs → Records detector → rows? → problem → standard flow
                          none  → no problem (or problem closes)
```
