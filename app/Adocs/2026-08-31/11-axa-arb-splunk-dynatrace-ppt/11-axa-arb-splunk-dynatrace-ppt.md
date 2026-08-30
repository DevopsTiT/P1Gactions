# AXA ARB Style Splunk Dynatrace PPT

## Decision tree

```
Need a PPT like the AXA Japan ARB pack?
  Topic = P260120F Splunk → Dynatrace?
    YES → open generated .pptx below
  Need to regenerate after edits?
    Edit 11_generate_arb_pptx.py → run generator with local venv
  Need formal board look?
    Merge official AXA Japan ARB master (ver.5.2) branding / D-PRA wallpaper / full HLD graphic
  Still open before ARB?
    Security TBA · Architect name · Decommission · Cloud Binding · Impacted Apps list
```

---

## Short takeaway

| Key point | Detail |
| --- | --- |
| Deliverable | ARB-style PowerPoint for **P260120F Splunk to Dynatrace** |
| File | `11-P260120F-Splunk-to-Dynatrace-ARB-style.pptx` |
| Slides | 12 widescreen slides (title → summary → AS-IS/TO-BE → data → security → open items) |
| Source facts | Captured from your ARB screenshots (Daily Files seq 10) |
| Not official | Working copy; merge AXA Japan ARB master template for the real board |

---

## Summary

A 12-slide widescreen deck was generated in an AXA-Japan-ARB-like layout: navy headers, Key Message bars, summary tables, AS-IS/TO-BE context boxes, data/security flows, and an open-items checklist. Content is the P260120F Splunk → Dynatrace Gate2 Build + Cloud Permit story. Regenerate anytime with the Python script and the local venv that has `python-pptx`.

---

## Main content

### Slide list

| # | Slide | What it covers |
| --- | --- | --- |
| 1 | Title | P260120F, Gate2 Build+Cloud Permit, PoCs, ARB 2026/06/26 |
| 2 | Approval / matrix | Simplified Mandatory PA/BP/CP/IR checklist |
| 3 | Summary Sheet | WHY, design overview, cost 25M Yen, Q3-2026, security TBA |
| 4 | Update & Approval History | HLD added; PA 2026/05/15; BP 2026/06/26 THIS ARB |
| 5 | AS-IS context | OpenPaaS/Lambda → S3 → Splunk MPI hub |
| 6 | TO-BE context | Sources → Dynatrace SaaS hub; Ex-ADL new in scope |
| 7 | Impacted Platforms | IT Platform + Cloud primary; Ex-ADL scope add |
| 8 | D-PRA alignment | SaaS / IaaS-PaaS-XaaS / Ops monitoring layer |
| 9 | Data Architecture | Ingestion → Store → Query; 3 months / MyAXA 1 year |
| 10 | Security Architecture | OneAccount + RBAC → Dynatrace console |
| 11 | HLD overview | Proxy, ActiveGate, OpenPaaS, Firehose, Local HUBs |
| 12 | Open items | Security TBA, decommission, CP checklist, app list |

### File locations

| Path | Role |
| --- | --- |
| Daily Files `.../11-axa-arb-splunk-dynatrace-ppt/11-P260120F-Splunk-to-Dynatrace-ARB-style.pptx` | Main PPT |
| Same folder `11_generate_arb_pptx.py` | Regenerator |
| Adocs twin | `/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-08-31/11-axa-arb-splunk-dynatrace-ppt/` |
| Adocs `.venv/` | Local python-pptx (do **not** git commit the venv) |

### How to regenerate

Commands are in [11.sh](./11.sh). Review and run yourself:

1. Ensure venv with `python-pptx` exists (or recreate).
2. Run `11_generate_arb_pptx.py`.
3. Open the new `.pptx` in PowerPoint / Keynote.

### Honest limits vs official ARB pack

| Official pack has | This working PPT has |
| --- | --- |
| AXA logo / master theme | Navy ARB-like styling only |
| Full OneAXA domain map graphic | Table summary of impacted platforms |
| Visio HLD with exact ports | HLD table + note to paste official graphic |
| Cloud Binding checklist pages | Called out as open item |
| Decommission Plan page | Called out as open item |

---

## Data flow map

```
[Your ARB screenshots]
        |
        v
[Seq 10 capture md]
        |
        v
[11_generate_arb_pptx.py + python-pptx]
        |
        v
[11-P260120F-Splunk-to-Dynatrace-ARB-style.pptx]
   title → matrix → summary → history
   AS-IS → TO-BE → platforms → D-PRA
   data → security → HLD → open items
```

---

## Related files

| File | Purpose |
| --- | --- |
| [11.sh](./11.sh) | Regenerate / open commands (one-liners) |
| [11-axa-arb-splunk-dynatrace-ppt-follow.txt](./11-axa-arb-splunk-dynatrace-ppt-follow.txt) | Chat-ready note |
| Fact source | Daily Files `2026-08-31/10-axa-arb-splunk-dynatrace-migration/` |
| Adocs twin | `app/Adocs/2026-08-31/11-axa-arb-splunk-dynatrace-ppt/` |

---

## Commands

See [11.sh](./11.sh). Do not auto-run unless you ask.
