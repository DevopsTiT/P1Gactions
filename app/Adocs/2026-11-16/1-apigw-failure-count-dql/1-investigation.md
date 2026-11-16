# Investigation

Panel title: `APIGW WPALJA21BC & WPALJA21B9 Failed Count`.

The search filters index `eip1015`, sourcetype `eip_mediator_serverlog`, and `Status=FAILURE`. The first host is `WPALJA21BC.prprivmgmt.intraxa`. `append` adds the same FAILURE rows from `WPALJA21B9.prprivmgmt.intraxa`. `stats count as ErrorCount by Status` counts that stack.

The time range is the dashboard shared time picker. Auto refresh is 1 minute. That refresh is a dashboard setting.
