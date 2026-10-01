# SILVA Verify Checklist Picture

```
PREVIEW ready?
  A. each sys_id real and active?   → no: fix mapping or tag
  B. choice values valid?           → no: change value
  C. open duplicate exists?         → yes: OPEN skips (correct)
  D. after stg POST, read back same? → empty: key dropped | changed: business rule
  all yes → mapping proven
```

```
payload → sys_user / sys_user_group / cmdb_ci_service / service_offering / cmdb_ci / core_company
        → sys_choice
        → incident (duplicate)
        → POST → incident read back → compare
```
