# Control-M Alerts V2 Investigation

| Screenshot | Finding |
|---|---|
| 1 | CH:UL Email Job status, same as seq 30 |
| 2 | CHDE010MJob Status for MyAXA UL Email, 30 11 * * 1-6, yesterday's order date |
| 3 | CHDR010M, 06:00, CC chen and a Teams channel |
| 4 and 5 | ジョブ実行結果通知, To tadashi.yoshida, CC $result.Email$, throttle 10 min |
| 6 and 7 | リラン確認, only action "Output results to lookup" to ControlmRerunHistory.csv |
| 8 and 9 | PDDW0100 Status, To fukuda and tsumura, CC UOG list, Highest, 担当各位 message, inline table |
| 10 and 11 | PDDW0100 Status_test, To hasegawa, subject 【test】 |
| 12 and 13 | PDDW0100 Status複製, To chen |
| 14 and 15 | Job Status for MyAXA UL Email, 30 11 * * 2-6, dedup job_name, CC ops guild and tadashi.yoshida |
| 16 and 17 | Job Status for MyAXA UL Email複製, 25 11 * * 1-6, To chen, message about data creation days |

| Observation | Meaning |
|---|---|
| リラン確認 has no email | It is state housekeeping, not an alert |
| Two CHDE010M reports at 11:30 to the same list | Recipients get two near-identical emails |
| Three copies | Leftover tests in Splunk |
