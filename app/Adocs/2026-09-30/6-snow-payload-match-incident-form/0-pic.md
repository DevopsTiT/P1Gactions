# SNOW Payload Pic

```
settings ─────────┐  caller, on behalf of, contact type, category, subcategory, impact, urgency
SILVA lookups ────┼─► snow_incident_payload ─► snow_form_check ─► ready_for_snow
event fields ─────┘  environment, short description, summary, correlation id
```

```
business_service
 ├─ CI link found → use it
 ├─ scored search clear winner → use it
 └─ nothing → Third Party Services Monitoring Application (default)
```
