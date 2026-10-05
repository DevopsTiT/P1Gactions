# Control-M Alerts Full Inventory V2

## Decision tree

```
17 more screenshots of the controlm_temp alert list
 alert name ends in _test or 複製 (copy)?      → do not migrate (test and personal copies)
 only action is "Output results to lookup"?   → not an alert, do not migrate (リラン確認)
 same job, same list, same time as another?   → merge (two CHDE010M 11:30 reports)
 action now visible?                          → fill in real recipients and message text (PDDW0100)
 everything else                              → unchanged from seq 30
```

## Short takeaway

| Question | Answer |
|---|---|
| What changed from seq 30? | 13 Splunk alerts are now known. 4 are not migrated, and the result is 1 detector plus 6 workflows |
| Why drop リラン確認? | Its only action writes ControlmRerunHistory.csv. It never notified anyone |
| Why drop three alerts? | They are a test copy (`_test`) and two personal copies (`複製`) |
| What was merged? | "CHDE010MJob Status for MyAXA UL Email" and "Job Status for MyAXA UL Email" both mail the same list at 11:30 |
| What was filled in? | PDDW0100 recipients, its 担当各位 message, and the CHDE010M body format |

## Summary

The new screenshots show the full `controlm_temp` alert list, including copies and the actions that were hidden before. リラン確認 turns out to be housekeeping (it maintains a CSV), not a notification, so the seq 30 rerun workflow is removed. Two CHDE010M reports that hit the same list at the same time are merged, and three test or personal copies are left behind in Splunk.

## Full inventory (13 Splunk alerts)

| # | Splunk alert | Schedule | Action | Dynatrace v2 |
|---|---|---|---|---|
| 1 | CH:UL Email Job status | 0 13 * * 2-6 | Email noda, yasuda and one more | Daily report `chde010m_ul_today` |
| 2 | CHDE010MJob Status for MyAXA UL Email | 30 11 * * 1-6 | Email digital marketing squad and emma support | Merged into `chde010m_myaxa_ul` |
| 3 | Job Status for MyAXA UL Email | 30 11 * * 2-6 | Same list, CC ops guild and tadashi.yoshida | Merged into `chde010m_myaxa_ul` |
| 4 | Job Status for MyAXA UL Email複製 | 25 11 * * 1-6 | Email shunjin.chen only | Not migrated (personal copy) |
| 5 | CHDR010MJob Status for MyAXA User Registration Batch | 06:00 daily | Email the same lists, CC chen and a Teams channel | Daily report `chdr010m_user_registration` |
| 6 | Claims Status Service PDDW0100 Status | 15 8 * * * | Email akio.fukuda.ose and ryusuke.tsumura, CC a UOG list | Daily report `pddw0100_claims_status` |
| 7 | Claims Status Service PDDW0100 Status_test | 15 8 * * * | Email koichi.hasegawa.ose, subject 【test】 | Not migrated (test) |
| 8 | Claims Status Service PDDW0100 Status複製 | 15 8 * * * | Email shunjin.chen | Not migrated (personal copy) |
| 9 | CTL-M アベンドアラートV2 | Every minute | Not visible | Detector `controlm_job_abend` |
| 10 | CTL-M:アベンドアラート | Every minute | Not visible | Detector `controlm_job_abend` |
| 11 | CTL-M:ジョブ実行結果通知 | Every minute | Email tadashi.yoshida, CC per-job contact | Workflow `controlm_job_result_notify` |
| 12 | CTL-M:リラン確認 | Every 4 minutes | Output results to lookup ControlmRerunHistory.csv | Not migrated (no notification) |
| 13 | Claim Job Over Run Alert | Every 5 minutes | Email claims incident list | Workflow `claims_job_overrun` |

## What changed in the Terraform

| Change | Detail |
|---|---|
| Removed `controlm_rerun_check` | リラン確認 only writes a CSV. Nobody received an email from it |
| Merged CHDE010M 11:30 reports | Keeps the "yesterday's order date" logic. To is the squad and emma support; CC is ops guild and tadashi.yoshida |
| CHDE010M body | Uses the Splunk message format: "The job status of CHDE010M", then JOB NAME, JOB STATUS, JOB START lines |
| Subject shows MSG | Like Splunk "$name$ $result.MSG$": the subject ends with OK or 正常終了していません要確認 |
| PDDW0100 recipients | To akio.fukuda.ose and ryusuke.tsumura, CC the UOG list (partly unreadable, marked CONFIRM) |
| PDDW0100 intro | "担当各位 PDDWの完了時刻のレポートを送信致します。" |

Key parts of the merged entry:

```hcl
chde010m_myaxa_ul = {
  title = "Prod_MyAXA_UL_CHDE010M_JobStatus_Normal"
  cron  = "30 11 * * 1-6"
  to    = ["digital_marketing_squad@axa.co.jp", "axa_jp_dl_emma_support@axa.co.jp"]               # CONFIRM
  cc    = ["alj_jp_dl_ops_guild_marketing_servicing@axa.co.jp", "tadashi.yoshida@axa.co.jp"] # CONFIRM
  ...
  line  = "JOB NAME: {{ r.job_name }}\nJOB STATUS: {{ r.status }}\nJOB START: {{ r.StartTime }}\nJOB END: {{ r.EndTime }}\nORDER DATE: {{ r.odate }}\n{{ r.MSG }}\n"
}

subject = "${each.value.title} {{ result(\"get_rows\").records[0].MSG | default(\"\") }}"
content = "${local.report_intro[each.key]}\n\n{% for r in ... %}${each.value.line}\n{% endfor %}"
```

## Things Splunk did that Dynatrace email does not copy

| Splunk setting | What happens in Dynatrace |
|---|---|
| Priority Highest (PDDW0100) | The email action has no priority flag. Put 【重要】 in the subject if the team relies on it |
| Inline table | The workflow writes one line per row in plain text |
| Link to Alert | No equivalent needed; the workflow execution is visible in Dynatrace |
| Allow Empty Attachment | Not needed; the email is skipped when there are no rows |

## Notes on the copies

| Copy | Why it exists (best guess) | What to do |
|---|---|---|
| Job Status for MyAXA UL Email複製 | shunjin.chen testing a new message explaining when data is created (週次: 週の第1営業日の翌日 11:00, 月次: 月の第1営業日の翌日) | If that explanation should go to the real list, add it to `report_intro["chde010m_myaxa_ul"]` |
| PDDW0100 Status複製 | shunjin.chen receiving his own copy | Add him to CC on the real report if he still needs it |
| PDDW0100 Status_test | Test of the subject 【test】 | Drop |

## Data flow

```
Control-M → controlm_temp (activejobs + alert) → Grail
   ├─ Ended not OK → detector per job → problem → standard flow
   ├─ 06:00, 08:15, 11:30, 13:00 → daily report workflow (4 entries) → email
   ├─ every 5 min → job_result_notify → 1 email per abended job that ended
   └─ every 5 min → claims_job_overrun → email once per stuck run
Not migrated: リラン確認 (CSV only), _test, 複製 x2
```

## Investigation

| Screenshot | Finding |
|---|---|
| 1 | CH:UL Email Job status, same as seq 30 |
| 2 | CHDE010MJob Status for MyAXA UL Email, 30 11 * * 1-6, yesterday's order date |
| 3 | CHDR010M, 06:00, CC chen and a Teams channel |
| 4 and 5 | ジョブ実行結果通知, To tadashi.yoshida, CC $result.Email$, throttle 10 min |
| 6 and 7 | リラン確認, only action "Output results to lookup" to ControlmRerunHistory.csv |
| 8 and 9 | PDDW0100 Status, To fukuda and tsumura, CC UOG list, Highest, 担当各位 message, inline table |
| 10 and 11 | PDDW0100 Status_test, To hasegawa, subject 【test】 |
| 12 and 13 | PDDW0100 Status複製, To chen, Highest, inline table |
| 14 and 15 | Job Status for MyAXA UL Email, 30 11 * * 2-6, dedup job_name, CC ops guild and tadashi.yoshida, subject "$name$ $result.MSG$" |
| 16 and 17 | Job Status for MyAXA UL Email複製, 25 11 * * 1-6, To chen, message about data creation days |

The Teams channel address was not copied.

## Result

| Step | Action |
|---|---|
| 1 | Use `31-controlm-alerts-full-inventory-v2.tf` instead of the seq 30 file |
| 2 | Confirm the merged CHDE010M report is fine with the marketing squad (they now get one email, not two) |
| 3 | Confirm the PDDW0100 CC list address |
| 4 | Ask whether anyone reads ControlmRerunHistory.csv (a dashboard maybe). If yes, rebuild it as a Notebook or dashboard query |
| 5 | Run the checks in `check.dql` (same as seq 30) |
| 6 | `terraform plan` should show 1 detector and 6 workflows (4 daily reports + result notify + overrun) |
| 7 | After cutover, disable all 13 Splunk alerts, including the copies |

## Related files

| File | Purpose |
|---|---|
| `31-controlm-alerts-full-inventory-v2.tf` | v2 detector and workflows |
| `31-controlm-alerts-full-inventory-v2-check.dql` | Same checks as seq 30 |
| `31.sh` | Commands |

## Commands

See `31.sh`. Not run.

```
terraform init
terraform validate
terraform plan
```
