# Dynatrace Workflow Import JSON Or YAML

```
Need to upload into Dynatrace Workflows?
  │
  ├─ Full backup / same tenant restore? → JSON (Download → Workflow)
  └─ Share / new tenant / template like AGO hosts? → YAML (Download → Template)
```

| Key point | Detail |
| --- | --- |
| Workflow file | **JSON** |
| Template file | **YAML** |
| Our SNOW+PD pack | Use **`.workflow-template.yaml`** |
| UI | Workflows → **Upload** → pick `.json` or `.yaml` |

## Summary

Dynatrace accepts **both**. **JSON** is a full workflow export. **YAML** is a **template** (connections cleared, apps listed as requirements). For the files we generated (`ago-problem-to-snow-pagerduty.workflow-template.yaml`), import as a **template (YAML)**.

---

## Comparison

| Item | JSON (Workflow) | YAML (Template) |
| --- | --- | --- |
| Download menu | Download → **Workflow** | Download → **Template** |
| File type | `.json` | `.yaml` |
| Contents | Full workflow + connection/user refs | Portable template; connections cleared |
| Best for | Backup, clone in same setup | Share across tenants / Hub-style start |
| After upload | Replace or Keep both if ID exists | Map Required apps + Connections, then Import |

---

## How to upload

1. Dynatrace → **Workflows**
2. Select **Upload**
3. Choose:
   - workflow **JSON**, or  
   - workflow template **YAML**
4. For templates: review **Required apps** → **Required connections** → **Import**

Official docs:

- [Upload a workflow or template](https://docs.dynatrace.com/docs/analyze-explore-automate/workflows/manage-workflows/workflows-upload)  
- [Download a workflow or template](https://docs.dynatrace.com/docs/analyze-explore-automate/workflows/manage-workflows/workflows-download)

---

## What to use for our pack

| File | Format | Action |
| --- | --- | --- |
| `ago-problem-to-snow-pagerduty.workflow-template.yaml` | YAML template | Upload as template |
| `ago-problem-closed-resolve-snow-pd.workflow-template.yaml` | YAML template | Upload as template |

Path: `Daily Files/2026-09-13/2-problem-snow-pd-workflow-yaml/`

Do **not** rename them to `.json` — template import expects **YAML**.

---

## Data flow

```
Download Workflow  → .json  → Upload → restore full workflow
Download Template  → .yaml  → Upload → pick connections → new workflow
```

## Related files

| File | Purpose |
| --- | --- |
| `3.sh` | UI one-liners |
| Seq 2 YAML pack | SNOW + PD workflow templates |

## Commands

See `3.sh`.
