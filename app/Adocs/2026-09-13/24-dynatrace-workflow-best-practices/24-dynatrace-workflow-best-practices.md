# Dynatrace Workflow Best Practices

```
What is “good” for Dynatrace Workflows?
  │
  ├─ Design: one job per workflow; clear trigger filters
  ├─ Secrets: Connections / UI — not passwords in Git
  ├─ Reliability: stable correlation keys; test open+close
  ├─ Safety: non-prod first; least privilege; rate limits
  └─ Ops: name owners; watch Executions; document runbooks
```

## Short takeaway

| Key point | What it means |
| --- | --- |
| Best practise (overall) | Small, clear workflows; secrets outside Git; filtered triggers; test before prod |
| For your SNOW+PD case | Two workflows (open create / close resolve); Connection for SNOW; shared Problem ID keys |
| Avoid | One giant workflow; secrets in YAML; no filters; random IDs each run |

## Summary

Treat a Workflow like a small production automation: give it one job, a tight trigger, safe credentials, and a way to prove it worked. For Problem → ServiceNow + PagerDuty, that means separate open/close workflows, Dynatrace Connections for ServiceNow, stable `correlation_id` / `dedup_key`, and a non-prod demo before going live.

---

## 1. Design practices

| Practice | What it means | Why you care |
| --- | --- | --- |
| One job per workflow | Open creates tickets; close resolves them | Easier to debug and change |
| Clear name + description | e.g. `AGO - Problem to ServiceNow and PagerDuty` | On-call knows what it does |
| Simple task graph | prepare → parallel work → sync | Humans can follow Executions |
| Parallel only when independent | SNOW create and PD trigger after prepare | Faster; no false dependency |
| Stable IDs | Same Problem ID family every time | Close can find the right ticket/page |

```
Good:  WF-A open | WF-B close
Bad:   one mega-workflow that does everything with unclear branches
```

**Your case:** keep create YAML and close YAML as **two** workflows (already best practise).

---

## 2. Trigger practices

| Practice | What it means | Why you care |
| --- | --- | --- |
| Filter severity | e.g. Error+ only | Less noise / fewer junk INCs |
| Filter tags/env | e.g. `env:prod` when live | Lab problems do not page prod |
| Match open vs close correctly | `onProblemClose: false` vs `true` | Right robot runs |
| Respect maintenance | Skip or never fire during windows as designed | Avoid false pages |
| Start broad in lab, tighten for prod | Empty filters only for first test | Safe go-live |

---

## 3. Secrets and config practices

| Practice | What it means | Why you care |
| --- | --- | --- |
| SNOW via **Connection** | No password in script/Git | Credential leaks and rotation |
| PD key out of Git | Secret store or paste in UI after import | Routing key is a secret |
| Config vs secret split | Maps/sys_ids/runbooks in prepare OK | Editable without exposing secrets |
| Least privilege SNOW user | Only incident create/update/search needed | Blast radius |
| Allow only needed hosts | SNOW instance + `events.pagerduty.com` | Network hygiene |

See also: `../22-better-than-hardcoded-placeholders/`

---

## 4. Reliability practices

| Practice | What it means | Why you care |
| --- | --- | --- |
| Correlation keys | SNOW `correlation_id` = Problem ID; PD `dedup_key` = `dt-problem-<id>` | Open and close stay linked |
| Never random new keys per run | Do not invent UUID each execution | Resolve breaks |
| Cross-link after both creates | Work notes with PD key | Humans can match tickets |
| Handle missing INC on close | Log skip / alert; do not silent-fail forever | Visibility |
| Watch Executions | Red task → fix that system first | Fast MTTR for automation |

---

## 5. Safety and change practices

| Practice | What it means | Why you care |
| --- | --- | --- |
| Non-prod / demo PD service first | Test pages do not wake real on-call | People trust the system |
| Change in Git or export after edit | Know what changed | Audit |
| Small changes + re-test open and close | Both halves of the lifecycle | Close often forgotten |
| Hourly execution limit awareness | Cap abuse / storm | Protect APIs |
| Do not auto-force unlock style hacks | N/A here but mindset: no blind destructive fixes | Safety culture |

---

## 6. Permissions practices

| Practice | What it means |
| --- | --- |
| Workflow IAM | read/write/run + app-engine functions as needed |
| Authorization consent | Including `app-settings:objects:read` for Connections |
| Share Connection | Runners can **use** the Connection |
| Separate human roles | Who edits workflows vs who only views Executions |

Detail: `../5-setup-snow-pd-workflow-steps-perms/`

---

## 7. Naming and ownership

| Practice | Example |
| --- | --- |
| Prefix by team/product | `AGO - …` |
| Say open or close in title | `… Problem open create` / `… Problem closed resolve` |
| Document owner | Who gets paged if the workflow itself fails |
| Link runbook in ticket text | Already in your description template |

---

## 8. Test practices (before calling it “done”)

| Test | Pass when |
| --- | --- |
| Create path | 4/4 tasks OK; INC + PD + work notes |
| Keys | `correlation_id` and `dedup_key` match Problem ID family |
| Close path | INC Resolved; PD resolved |
| Filter | Lab tag does not fire prod workflow (after tighten) |
| Failure drill | Bad password → clear red task (you can see it) |

Demo monitor steps: `../12-monitor-snow-pd-demo-steps/`

---

## 9. Anti-patterns (avoid)

| Anti-pattern | Why it hurts |
| --- | --- |
| Secrets committed in YAML/JSON | Leak + hard rotation |
| Uploading YAML **and** JSON for the same job | Duplicate workflows / double tickets |
| Merging open+close into one import file | Wrong model for Dynatrace upload |
| No trigger filters in prod | Alert storms → ticket storms |
| Random `dedup_key` each run | Cannot resolve PD |
| Only testing create, never close | Stale INCs and open pages |
| Huge unreadable JS with no prepare step | Hard to change field mapping |

---

## 10. Best-practise checklist for your SNOW+PD pack

- [ ] Two workflows: create (open) + resolve (close)  
- [ ] Prefer YAML upload; one format only per workflow  
- [ ] SNOW password via **Connection** (not long-term in file)  
- [ ] PD key not in Git  
- [ ] `correlation_id` + `dt-problem-<id>` stable  
- [ ] Trigger filters for prod  
- [ ] Demo on non-prod / demo PD service  
- [ ] Executions reviewed on first real Problem  
- [ ] Owner + runbook known  

---

## Data flow map (practise applied)

```
Git: workflow logic + assignMap (config)
Dynatrace Connection: SNOW URL/user/password
UI/secret: PD routing key
        │
        ▼
Filtered Problem OPEN → create WF → INC + PD + cross-link
Filtered Problem CLOSE → close WF → resolve both
        │
        ▼
Executions + INC + PD = proof it worked
```

## Related files

| Path | Why |
| --- | --- |
| `../22-better-than-hardcoded-placeholders/` | Secrets practise |
| `../9-one-or-two-workflow-files/` | Two-workflow practise |
| `../18-upload-json-or-yaml/` | Upload practise |
| `../12-monitor-snow-pd-demo-steps/` | Test/demo practise |
| `../8-dynatrace-snow-pd-detailed-design/` | Full design |
| `24.sh` | Reminders |

## Commands

See `24.sh` in this folder.
