# OPEN v7 Picture

```
problem → extract → resolve (GET) → build-payload
   decision no      → skip, skip
   sample / exists  → skip, skip
   DRY_RUN          → dry_run, dry_run
   ok               → POST SILVA → PD trigger
keys: u_business_service | cmdb_ci (offering) | u_configuration_item (host)
```
