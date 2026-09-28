# Investigation

| What was checked | What it showed |
|---|---|
| Screenshot: Number | INC30339677, state New. |
| Screenshot: Contact type and Summary | Event, plus the "Additional Information" JSON. The OPEN workflow created it. |
| Screenshot: Summary JSON correlation_id | P-260915247, the same as External Ticket Number. |
| Screenshot: Summary JSON problem_id | -7958242114081464045_1790571960000V2 (read from a photo, so double-check it). |
| Screenshot: Assignment group | testing 3122. |
| Screenshot: Business service and Service offering | QA Platforms, while the Summary JSON says Third Party Services Monitoring Application. |
| CLOSE YAML (seq 8), line 82 | problemId = display_id, so correlation_id = P-260915247. |
| CLOSE YAML (seq 8), line 194 | Searches incidents by correlation_id. |
| CLOSE YAML (seq 8), lines 223 to 228 | Resolves with state 6, close_code, close_notes and comments. |
