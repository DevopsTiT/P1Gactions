# Result

1. Set the close workflow trigger Event state to **closed** (dropdown), Save, Deploy.
2. Or import v5 and confirm the panel shows **closed**; if not, select it by hand.
3. Replace the imported v1 with v5 (has the incident_state fix and the closed guard).
4. Test with a real closed problem or a manual Run (SAMPLE_EVENT + ALLOW_SAMPLE_POST).
5. Expected: SILVA Incident State = Resolved, PagerDuty incident resolved.
