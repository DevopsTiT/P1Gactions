# Decide The Log Path Scope

```
Add /app/ICM_CPW/log/ap/default.log to CEAA20F7's host group?
  what are you trying to see?
    claim-payment logs only
      CEAA20F7 is labeled FileNet → leave the group out
    this same file on this host
      file missing on the server → leave it out
      file present
        other hosts in HOST_GROUP-9034BF4FC7D158B2
          they should not send this file → do not use this group scope
          they should send it → continue
        personal data in the file
          mask does not cover this path → do not turn on storage yet
          mask covers this path → add custom source and log storage together
```

```
Purpose
  claim-payment only → stop, three hosts already covered
  need CEAA20F7 too
        |
        v
File on CEAA20F7?
  no → stop
  yes
        |
        v
Every host in HOST_GROUP-9034BF4FC7D158B2?
  no → stop, do not use this group
  yes
        |
        v
Mask matches this log path?
  no → stop, storage stays off
  yes
        |
        v
One change
  custom log source
  log storage, send_to_storage true
```
