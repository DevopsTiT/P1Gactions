# Glossary

| Term | What it means |
|---|---|
| state | Standard task state field on the incident. |
| incident_state | Incident-specific state field; SILVA's form label "Incident State". |
| State model | Rules for which state can follow which (for example New cannot jump to Resolved). |
| sys_audit | ServiceNow table recording every field change: who, when, old value, new value. |
| Business rule | Server-side script in SILVA that can change or reject field values on save. |
| active | true until the incident is Closed or Canceled; may stay true while Resolved. |
