# Investigation

| Source | Finding |
|---|---|
| Data model title | `APIGW1015_Failure_count`. |
| Dataset id | `1600951249.6968_7EF4ECD2-84C5-40F9-B50C-B2D3D93AB3B9`. |
| Object name | `RootObject`. |
| Constraint | `index=eip1015 sourcetype=eip_mediator_serverlog Status=FAILURE`. |
| Search bar | `index=eip1015 sourcetype=eip_mediator_serverlog`. |
| Job state | Paused. Events tab shows 259,387. |
| source | `/opt/softwareag/log/1015/apigw5500/server.log`. Popup count 271,855. |
| host | Four values in `prprivngt.intraxa`: WPLALJ2BF 123,387, WPLALJ2CB 119,712, WPLALJ2BC 15,410, WPLALJ2BB 11,386. |
| Sample event | Status SUCCESS at 13:25:37 JST on 2026-10-29. |

The field-popup counts and the Events tab total differ. The job is paused.
