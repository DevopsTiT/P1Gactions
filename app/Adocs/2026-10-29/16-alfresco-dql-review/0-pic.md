# Alfresco DQL Review

```
Prod_PnC_Alfrescoacr_BatchPODFrozen_High
  Splunk Message = number of hosts
  Message is 4 → no row
  DQL on the screen
    total = count() by name → log lines per name
    filter total != 4 → names that did not write exactly 4 lines
  that is a different check
  use countDistinct of pod name or host name
  return one Total row only when that count is not 4
```

```
Splunk
  events → one row per host → Message = how many hosts
        |
        +-- Message is 4 → no row
        +-- Message is not 4 → one Total row

Screen DQL
  events → group by coalesced name → total = log lines
        |
        +-- that name wrote 4 lines → drop the name
        +-- that name wrote any other number → keep the name
```
