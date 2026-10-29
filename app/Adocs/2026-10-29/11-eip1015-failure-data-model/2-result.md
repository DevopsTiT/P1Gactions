# Result

The failure model keeps only this search:

```
index=eip1015 sourcetype=eip_mediator_serverlog Status=FAILURE
```

The open search stops after the sourcetype, so success rows remain. It is paused at 259,387 events over a long window. The red box counts failures for the dashboard time, which was Last 15 minutes.

Match the red box:

```
index=eip1015 sourcetype=eip_mediator_serverlog Status=FAILURE
| stats count
```

Failures by host:

```
index=eip1015 sourcetype=eip_mediator_serverlog Status=FAILURE
| stats count by host
| sort - count
```

Set the time picker to Last 15 minutes before comparing the result with the dashboard.
