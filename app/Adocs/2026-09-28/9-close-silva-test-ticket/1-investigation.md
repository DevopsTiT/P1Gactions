# Investigation

| What was checked | What it showed |
|---|---|
| Screenshot: Contact type | Phone, not Event. The ticket looks hand-made, not created by the workflow. |
| Screenshot: Short description and Summary | Both say "test". |
| Screenshot: Incident State | New. |
| Screenshot: Assignment group | testing 3122. |
| Screenshot: External Ticket Number | P-260915195 (a Dynatrace problem display ID). |
| Screenshot: INC number | Not visible in the photo, so it is unclear whether the form was saved. |
| CLOSE workflow (seq 8), lines 223 to 228 | Resolves with state "6", close_code "Solved (Permanently)", close_notes and comments. |
| CLOSE workflow search | Finds the incident by correlation_id only, so a hand-made ticket is not found. |
