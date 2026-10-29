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

| Key point | Detail |
|---|---|
| Data model | `APIGW1015_Failure_count`. |
| Constraint | `index=eip1015 sourcetype=eip_mediator_serverlog Status=FAILURE`. |
| Object | `RootObject`. The pivot counts this object. |
| Dataset id | `1600951249.6968_7EF4ECD2-84C5-40F9-B50C-B2D3D93AB3B9`. |
| Open search | Same index and sourcetype, without `Status=FAILURE`. |
| Events tab | 259,387. The search is paused. |
| Log file | `/opt/softwareag/log/1015/apigw5500/server.log`. |

## Summary

The red failure number counts events that match three filters: index `eip1015`, sourcetype `eip_mediator_serverlog`, and `Status=FAILURE`, inside the dashboard time range. The search open beside it uses the same index and sourcetype and leaves `Status=FAILURE` off, over a longer window. Its 259,387 events include success rows. That count is the wider log, not the red box.

## Investigation

| Source | Finding |
|---|---|
| Data model title | `APIGW1015_Failure_count`. |
| Dataset id | `1600951249.6968_7EF4ECD2-84C5-40F9-B50C-B2D3D93AB3B9`. |
| Object name under that id | `RootObject`. |
| Constraint box | `index=eip1015 sourcetype=eip_mediator_serverlog Status=FAILURE`. |
| Extracted fields on screen | `API`, `Application_Name`, `host`, `Operation_Resource_Name`, `Session_ID`, plus the usual time and index fields. The list continues below the fold. |
| Search bar | `index=eip1015 sourcetype=eip_mediator_serverlog`. |
| Job state | Paused. No event sampling. |
| Events tab | 259,387. |
| Timeline | Starts about 6:00 PM on Wed Oct 28. A visible event is 13:25:37 JST on Oct 29. |
| source popup | One path: `/opt/softwareag/log/1015/apigw5500/server.log`. The popup count reads 271,855. |
| host popup | Four hosts. Counts on the popup: WPLALJ2BF 123,387, WPLALJ2CB 119,712, WPLALJ2BC 15,410, WPLALJ2BB 11,386. Domain is `prprivngt.intraxa`. |
| Sample event | The opened row shows `Status: SUCCESS`. |

The Events tab total and the field-popup counts are different. The job is paused, so those popups are the field window on this job, not a second finished total.

## Result

A constraint is the search Splunk applies before the pivot counts. Only events that match every part of it enter the model.

| Filter | What it keeps |
|---|---|
| `index=eip1015` | The EIP 1015 index. |
| `sourcetype=eip_mediator_serverlog` | Mediator server log events. |
| `Status=FAILURE` | Rows whose Status field is FAILURE. |

`RootObject` is the name of that event set. The long id is the dataset id. The pivot column `Count of 1600951249.6968_7EF4ECD2-84C5-40F9-B50C-B2D3D93AB3B9` is “count of this dataset.”

The dashboard panel runs that count for the shared time picker, which was Last 15 minutes, and refreshes every minute.

The search that is open uses only the first two filters:

```
index=eip1015 sourcetype=eip_mediator_serverlog
```

It is paused at 259,387 events. The opened event is a SUCCESS at 13:25 JST on Oct 29. Success rows stay in this search. They stay out of the failure model.

The source popup shows one log file:

```
/opt/softwareag/log/1015/apigw5500/server.log
```

The host popup shows four hosts in `prprivngt.intraxa`:

| Host | Count on the popup |
|---|---|
| WPLALJ2BF.prprivngt.intraxa | 123,387 |
| WPLALJ2CB.prprivngt.intraxa | 119,712 |
| WPLALJ2BC.prprivngt.intraxa | 15,410 |
| WPLALJ2BB.prprivngt.intraxa | 11,386 |

Resume the paused search if you need the job to finish. Then read the Events tab again.

To see the same count the red box uses, put the third filter back and set the time picker to Last 15 minutes:

```
index=eip1015 sourcetype=eip_mediator_serverlog Status=FAILURE
| stats count
```

To see which host those failures came from:

```
index=eip1015 sourcetype=eip_mediator_serverlog Status=FAILURE
| stats count by host
| sort - count
```

`host`, `Application_Name`, `API`, and `Operation_Resource_Name` are extracted on the model, so the same `stats count by` pattern works for each of them.

## Data flow map

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

## Related files

| File | Purpose |
|---|---|
| `0-pic.md` | Decision tree and data flow. |
| `1-investigation.md` | What the three screens show. |
| `2-result.md` | The constraint and the matching searches. |
| `3-glossary.md` | Terms. |
| `11-eip1015-failure-data-model-follow.txt` | Same explanation for mobile. |
| `11.sh` | Copy commands. |

Commands: [11.sh](11.sh)
