# Dynatrace Failure Count Tile

```
Same number as APIGateway FAILURE
  are these logs in Dynatrace?
    discovery query returns no rows → ingest the server.log path first
    rows come back → which field holds the status text
  count tile
    log path apigw5500/server.log
    status text FAILURE
    dashboard time Last 15 minutes
    show 0 when nothing matches
  color → 1 and above red
  refresh → 1 minute
  host table → same filters, split by host.name
  success tile → same query, status text SUCCESS
```

```
server.log on the mediator hosts
 /opt/softwareag/log/1015/apigw5500/server.log
        |
        v
Dynatrace log ingest
        |
        v
Dashboard time picker = Last 15 minutes
 refresh every 1 minute
        |
        +--> failure tile
        |      log path + Status: FAILURE
        |      single value failure_count
        |      1 and above = red
        |
        +--> success tile
        |      same path + Status: SUCCESS
        |      green
        |
        +--> host table
               same failure filter
               one row per host.name
```
