# Open Close With Credentials

```
Ready to import?
 Password copied from a photo? → paste the real one over line 314 (OPEN) and 187 (CLOSE)
 Import OPEN + CLOSE → Workflows → Upload
 Allowlist set? → silvastg.service-now.com , events.pagerduty.com
 Test problem → INC in "testing 3122" + PD incident
 Going live? → TEST_ASSIGNMENT_GROUP = "" and move secrets to Credential Vault
```

## Short takeaway

| Question | Answer |
|---|---|
| What is this folder? | The seq 7 YAMLs with the SILVA password and the PagerDuty routing key filled in. |
| What changed from seq 7? | Only the two secret lines in each file, plus the header comment. |
| Where are the real values? | All three copies: Daily Files, AIProjects/Files and app/Adocs. |
| What is the risk? | app/Adocs is in a git repo that pushes to GitHub. Do not commit or push this folder. |

## Summary

These YAMLs are ready to import into Dynatrace. The only thing to double-check is the password, because it was read from a photo.

## Where the secrets are

| File | Line | Setting |
|---|---|---|
| `1-open-silva-http-and-pagerduty.workflow.yaml` | 314 | SILVA password (`const password`) |
| `1-open-silva-http-and-pagerduty.workflow.yaml` | 417 | PagerDuty routing key (`const routingKey`) |
| `2-close-silva-http-and-pagerduty.workflow.yaml` | 187 | SILVA password (`const password`) |
| `2-close-silva-http-and-pagerduty.workflow.yaml` | 268 | PagerDuty routing key (`const routingKey`) |

## Password characters to verify

| Spot | Used | Could also be |
|---|---|---|
| `Wnt0` | zero | capital O |
| `XIqw` | capital I | lowercase l |

## Data flow map

```
Problem ACTIVE → OPEN prepare-payload
   → post-silva-incident-http (Basic auth: Tech_DynatraceJP_WS + password) → INC in testing 3122
   → trigger-pagerduty (routing key) → PD incident
Problem CLOSED → CLOSE prepare-close-ids
   → resolve-silva-incident-http (same password) → INC Resolved
   → resolve-pagerduty (same routing key) → PD resolved
```

## Related files

| File | Purpose |
|---|---|
| `1-open-silva-http-and-pagerduty.workflow.yaml` | OPEN workflow with secrets |
| `2-close-silva-http-and-pagerduty.workflow.yaml` | CLOSE workflow with secrets |
| `../7-open-close-example-testing-group/` | Same workflows, explained |

No commands for this step.
