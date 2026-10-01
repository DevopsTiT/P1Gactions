# Glossary

| Term | What it means | Why you care |
|---|---|---|
| Field-level ACL | A rule that hides one field from some users | The API shows "" instead of the value |
| Row-level ACL | A rule that hides the whole record | The API returns no result |
| Custom field | A field added by the company, key starts with `u_` | The form label can point to it instead of the standard field |
| Instance | One ServiceNow site (silva = prod, silvastg = staging) | Same incident number can differ between them |
| `with_entries(select(...))` | jq filter that keeps only matching keys | Shows only service-related fields |
