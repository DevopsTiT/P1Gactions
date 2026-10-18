# S0 Preview Post SILVA PD Confluence

## Decision tree

```
Need Confluence page for S0 PREVIEW then POST workflow?
 → paste 4-s0-preview-post-silva-pd-event-path.wiki
 Insert → Markup → Confluence Wiki
 Cloud prefers Markdown?
 → paste 4-s0-preview-post-silva-pd-event-path.md
 Title: Dynatrace S0 Preview Then Post SILVA and PagerDuty
 Labels: dynatrace, silva, pagerduty, workflows, snow
```

## Short takeaway

| File | Use when |
|---|---|
| `4-s0-preview-post-silva-pd-event-path.wiki` | **Paste this** (recommended) |
| `4-s0-preview-post-silva-pd-event-path.md` | Markdown alternate |
| Source | Screenshot S0 v7.1 + `2026-10-01/36-standard-flow-preview-then-post` |

## Summary

Confluence-ready staff page explaining every task, branch, and API call for the Dynatrace S0 preview-then-post SILVA + PagerDuty workflow. No secrets in the page body.

## Investigation

### How to publish

1. Confluence → Create/Edit page.
2. **Insert → Markup → Confluence Wiki**.
3. Paste full contents of `4-s0-preview-post-silva-pd-event-path.wiki`.
4. Title: **Dynatrace S0 Preview Then Post SILVA and PagerDuty**.
5. Labels: `dynatrace`, `silva`, `servicenow`, `pagerduty`, `workflows`.
6. Review info/warning panels and tables.
7. Publish.

## Result

| Done | Evidence |
|---|---|
| Wiki pasted | Macros and tables render |
| Title set | Matches |
| No secrets | Passwords / routing keys absent |

## Data flow map

```
screenshot + seq 36 standard
  → .wiki / .md
  → Confluence page
```

## Related files

| File | Purpose |
|---|---|
| `4-s0-preview-post-silva-pd-event-path.wiki` | **Paste into Confluence** |
| `4-s0-preview-post-silva-pd-event-path.md` | Markdown alternate |
| `4-s0-preview-post-silva-pd-confluence.md` | This how-to |
| `../../2026-10-01/36-standard-flow-preview-then-post/` | Standard YAML (secrets — local only) |
| `4.sh` | Git one-liners (not run) |

## Commands

See `4.sh`. None have been run. Do **not** git-add the workflow YAML if it contains secrets.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-19/4-s0-preview-post-silva-pd-confluence
git commit -m "s0 preview post silva pagerduty confluence page"
git push
```
