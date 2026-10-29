# Host Logs Zero Meaning

```
Host page Logs = 0
  which clock? → Last 2 hours
  which host? → alfrescoacr-batch-innsuite-prod-0 only
  Dynatrace linked any log line to this host in that window?
    no → the Logs tile stays 0
  did the process write a file on disk?
    this page does not answer that
  Splunk index over ~24 hours still has events
    those lines are not on this host page
  confirm → DQL on host.name for 2 hours, then 24 hours
```

```
alfrescoacr-batch-innsuite-prod-0
        |
        +--> special agent inside the container
        |      process 1
        |      services 4
        |      connected entities 5
        |
        +--> host page, Last 2 hours, app only
               Logs 0
               Events 0
               CPU and network charts empty
        |
        +--> Splunk index alfrescoacr-batch
               events over the longer window
               not shown on this host page
```
