# Control-M Re-evaluation Investigation

| What was checked | Finding |
|---|---|
| Seq 31 tf (2026-10-05) | 1 makeTimeseries detector and 6 workflows |
| Workflows in seq 31 | 4 daily reports, job result notify, claims overrun |
| Current rules | Detectors only, Records analyzer, no makeTimeseries |
| Abend coverage | The abend detector covers every job, so report jobs failing are already alerted |
| Report emails | Their real signal is "the job did not end OK" |
| Not migrated | リラン確認 (CSV only), PDDW0100 _test, two 複製 copies |
