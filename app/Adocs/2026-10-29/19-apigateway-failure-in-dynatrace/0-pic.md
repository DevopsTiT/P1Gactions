# API Gateway Failure In Dynatrace

```
Edit Search titled APIGateway FAILURE
  pivot counts data model APIGW1015_Failure_count
    index eip1015
    sourcetype eip_mediator_serverlog
    Status=FAILURE
  time comes from the shared picker searchByTimer
  refresh every 1 minute
  the chart shows one number
Dynatrace
  logs for apigw5500/server.log must be ingested
  tile counts lines whose text contains Status: FAILURE
  dashboard time Last 15 minutes
  refresh every 1 minute
  single value, 1 and above red
```

```
server.log
 /opt/softwareag/log/1015/apigw5500/server.log
        |
        v
Splunk index eip1015
 sourcetype eip_mediator_serverlog
 Status=FAILURE
        |
        v
pivot count
 shared time picker
 refresh 1 minute
        |
        v
APIGateway FAILURE
 one red number

Same count in Dynatrace
 log.source contains apigw5500/server.log
 content contains Status: FAILURE
        |
        v
single value failure_count
 Last 15 minutes
 refresh 1 minute
 1 and above = red
```
