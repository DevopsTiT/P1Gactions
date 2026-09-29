# Result

| Item | Status |
|---|---|
| New workflow | `1-extract-tags-silva-enrichment.workflow.yaml` (3 tasks, no POST, no PagerDuty) |
| Test | Import, then Run. The sample Oracle event is used, and task `display-result` shows the JSON. |
| If enrichment is `found: false` | Check `lookup.steps`. Add the trigram to `SERVICE_MAP`, or check that the host exists in SILVA (`1.sh` lines 1–2). |
| If steps show 401 or 403 | Password or SILVA read access |
| Tags only, without SILVA | Set `ENABLED = false` in `lookup-silva` |
| Secret | The password is in the file. Do not push the app/Adocs copy. |
