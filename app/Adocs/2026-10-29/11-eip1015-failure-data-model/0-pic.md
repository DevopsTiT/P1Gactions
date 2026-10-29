# EIP1015 Failure Data Model

```
APIGateway FAILURE number
  pivot counts data model APIGW1015_Failure_count
    constraint is the real filter
      index=eip1015
      sourcetype=eip_mediator_serverlog
      Status=FAILURE
    dashboard time → last 15 minutes
  open search on screen
    same index and sourcetype
    no Status=FAILURE
    longer window, search paused
    Events tab shows 259,387
  want the same number as the red box
    add Status=FAILURE
    set the time picker to Last 15 minutes
    stats count
```

```
server.log
 /opt/softwareag/log/1015/apigw5500/server.log
 hosts BF, CB, BC, BB in prprivngt.intraxa
        |
        v
index=eip1015
sourcetype=eip_mediator_serverlog
        |
        +-- open search, no Status filter, long window
        |     paused at 259,387 events
        |     sample row is SUCCESS
        |
        +-- data model adds Status=FAILURE
                |
                v
           pivot count of RootObject
                |
                v
           APIGateway FAILURE
           dashboard time, refresh 1 minute
```
