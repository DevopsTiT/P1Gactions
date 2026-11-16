# Investigation

The two count queries returned 0 records for Last 1 hour. Both keep a row only when the parse fills `API`.

The check query returned 5 records. `log.source` is `/opt/softwareag/log/1015/apigw5590/server.log`. `host.name` is `WPALJA21BC.prprivmgmt.intraxa`. The visible start of `content` is the timestamp, `[YAI.0103.0074I]`, and `[default][W`. It does not show `API:`.
