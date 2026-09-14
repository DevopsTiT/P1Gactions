# One File Or Two Workflows

```
Put create + close in one YAML/JSON?
  │
  ├─ For Dynatrace Upload? → NO (one file = one workflow)
  ├─ For Git folder/zip? → YES (package both files together)
  └─ One workflow with open+close branches? → Possible but harder; not recommended for v1
```

| Key point | Detail |
| --- | --- |
| Upload rule | Each `.yaml` / `.json` imports **one** workflow |
| Your four files | Two workflows × two formats (YAML template + JSON) |
| Keep | Create file + Close file separate |

## Summary

Do **not** merge create and close into a single importable YAML or JSON. Dynatrace treats each uploaded file as one workflow with one trigger graph. Keep **WF-A (open)** and **WF-B (close)** separate. You can still store both in the same folder or zip for sharing.

## Why not one file

| Approach | OK? | Why |
| --- | --- | --- |
| One YAML with two full `workflow:` roots | No | Upload expects one template/workflow document |
| One workflow, trigger both open and close, branch in JS | Risky | Harder to debug; easy to create duplicate INC on updates |
| Two workflows, two files | **Yes** | Clear: open→create, close→resolve |
| One zip/folder containing both files | Yes | Packaging only, not a single Dynatrace document |

## What you should use

| Purpose | File |
| --- | --- |
| Problem open | `ago-problem-to-snow-pagerduty.workflow-template.yaml` or `.workflow.json` |
| Problem close | `ago-problem-closed-resolve-snow-pd.workflow-template.yaml` or `.workflow.json` |

Upload **twice** (or import both). Prefer **YAML templates** for first load across tenants.

## Related

Seq 4 pack · Seq 8 detailed design (two-workflow architecture).
