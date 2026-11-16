# Investigation

The panel search stacks host `WPALJA21BC.prprivmgmt.intraxa` and host `WPALJA21B9.prprivmgmt.intraxa`, both with `Status=FAILURE`, then counts them as `ErrorCount` by Status.

The BC job wrote `/opt/softwareag/log/1015/apigw5500/server.log`. The B9 job wrote `/opt/softwareag/log/1015/apigw5590/server.log`. Both line texts contain `status: FAILURE`.

The 101 and the 89 are from different time windows.
