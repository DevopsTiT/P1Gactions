# Investigation

The Splunk job returned 101 events from 2026-11-16 09:00:00 through 09:13:01.

Search: `index=eip1015 sourcetype=eip_mediator_serverlog host="WPALJA21BC.prprivmgmt.intraxa" Status=FAILURE`.

The host popup is only `WPALJA21BC.prprivmgmt.intraxa`, count 101. The source popup is only `/opt/softwareag/log/1015/apigw5500/server.log`, count 101. The line text contains `status: FAILURE`.
