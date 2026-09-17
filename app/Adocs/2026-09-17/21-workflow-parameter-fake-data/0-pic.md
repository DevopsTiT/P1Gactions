# Pic — Parameters And Fake Data

```
Fill before activate?
  Connection URL/user/pass
  __PD_ROUTING_KEY__
  __SNOW_*_SYS_ID__
  allowlist + ITSM OFF
  entity tag app:*
        │
        ▼
Problem event fills id/title/severity/tags
        │
        ▼
prepare computes impact/group/dedupKey/texts
        │
        ├─ snow-create-incident
        └─ PD trigger → comment → close resolve
```
