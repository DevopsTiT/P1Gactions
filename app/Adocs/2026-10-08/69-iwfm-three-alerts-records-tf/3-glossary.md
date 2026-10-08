# IWFM Three Alerts Glossary

| Term | What it means | Why you care |
|---|---|---|
| IWFM | The backend system that generates form images and reports. | All three alerts watch for it failing. |
| EIP | The integration layer (API mediator) between Compass and backend systems. | EIP006 failures usually mean IWFM is down or slow. |
| EIP006 | The GenerateFormImage-v2 service on EIP. | Its FAILURE status is what alert 1 counts. |
| fmwsagentlog | The log written by the IWFM agent. | Alert 3 reads Caution and Fatal lines from it. |
| Records detector | A Dynatrace detector that opens a problem for each row the query returns. | Lets us copy Splunk's "number of results > N" directly. |
| Identity field | The field that decides which rows belong to the same problem. | Here it is `check`, so each alert has one problem at a time. |
| Throttle | Splunk setting that stops repeat alerts for a time. | In Dynatrace an open problem does not re-notify, which does the same job. |
| transaction | Splunk command that groups related lines into one result. | Not needed here, because any error line already means "alert". |
| log.source | The Dynatrace attribute that says which file or stream a log came from. | It replaces Splunk's sourcetype filter. |
