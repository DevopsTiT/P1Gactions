# Blank Fields Picture

```
blank business service / offering / CI
 notes show uk-sap-fscd-dev -> workflow sent it
 one field-change entry -> sys_id PATCH skipped -> lookup found no sys_id
 FQDN sent as CI name -> no CMDB match -> no CI -> SILVA cannot derive service
 metadata has no system/snow-service/support-group tag -> defaults
fix: tolerant lookup + CI by sys_id + service from svc_ci_assoc + diagnostics
```
