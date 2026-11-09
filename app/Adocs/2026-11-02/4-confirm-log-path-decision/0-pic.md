# Confirm The Log Path Decision

```
Confirm the four checks
  1 purpose
    open CEAA20F7 and CEAA9026
    CEAA20F7 shows only FileNet → purpose is claim-payment hosts only → stop
    CEAA20F7 shows /app/ICM_CPW → continue
  2 file
    known hosts return the path in DQL
    CEAA20F7 returns 0 rows → Dynatrace is not storing it yet
    owner runs ls on the server
    file missing or old → stop
    file present and recent → continue
  3 host group
    host page shows HOST_GROUP-9034BF4FC7D158B2
    Hosts filter lists every member
    a member should not send this file → stop
    every member should send it → continue
  4 mask
    Settings → Log Monitoring → Sensitive data masking
    no enabled rule covers this path and this group → stop
    an enabled rule covers both → both Terraform blocks can go in one change
```
