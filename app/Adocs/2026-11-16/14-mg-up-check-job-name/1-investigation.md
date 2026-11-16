# Investigation

`restapi.job_name == "EIP IS UP check WPALJA21B8"` returned 288 records. `log.source` is `restapi-monitoring`. Content is `{"IS_Result":{"IS_Status":"EIP_UP"}}`.

The follow-up `or` used a bare string and failed with a boolean error. The Splunk panel wants `WPALJA21BC` and `WPALJA21B9` for the last 3 minutes, with `MG_Result.MG_Status`.
