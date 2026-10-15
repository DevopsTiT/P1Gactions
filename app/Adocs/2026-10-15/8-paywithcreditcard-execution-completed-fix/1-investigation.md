# PayWithCreditCard Execution Completed Investigation

| What was checked | Finding |
|---|---|
| Splunk search | `sourcetype="portals-amp-backend" earliest=-1h`, replace, `spath`, `message.url="*payWithCreditCard_Adj*" message.type="EXECUTION_COMPLETED"` |
| Splunk result | 68 events in the last hour. |
| Notebook type filter | `CAUGHT_EXCEPTION_ON_BACKEND`, which is not what Splunk searches for. |
| Notebook url filter | `== "payWithCreditCard_Adj"`, but url is the full https address. |
| Notebook unescape | The second `replaceString(..., "\\", "")` removes all backslashes. Splunk does not do this. |
| Dynatrace result | 0 records, 8.89 GiB scanned. |
| Earlier finding | 2026-10-14 answers 21 and 25 showed portals-amp logs are not in Dynatrace. |
