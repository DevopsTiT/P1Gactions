# All Dynatrace Dql Queries

```
Source: Splunk 1 copy.sh → Dynatrace DQL
Copy one query fence into Logs / Notebooks
Same time range as Splunk
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| Queries | **45** + Discover |
| File | `6-all-dynatrace-queries.md` |

## Summary

All Dynatrace DQL queries from the Splunk alert migration, in Markdown.

## Discover helper

```dql
fetch logs
| filter contains(aws.log_group, "<index-or-app>") or contains(log.source, "<index-or-app>")
| summarize count = count(), by: { aws.log_group, log.source }
| sort count desc
| limit 50
```

## 1. 1) cci-fa-comm-calc

```dql
fetch logs
| filter contains(aws.log_group, "cci-fa-comm-calc") or contains(log.source, "cci-fa-comm-calc")
| filter contains(content, "Task timed out", caseSensitive: false)
| filter not contains(content, "!DEBUG!")
| fields timestamp, aws.log_group, content
| sort timestamp desc
| limit 1000
```

## 2. 2) cmx-sharepoint-api

```dql
fetch logs
| filter contains(aws.log_group, "cmx-sharepoint-api") or contains(log.source, "cmx-sharepoint-api")
| filter contains(content, "Error", caseSensitive: false)
| fields timestamp, aws.log_group, content
| sort timestamp desc
| limit 1000
```

## 3. 3) compass-sales-performance

```dql
fetch logs
| filter contains(aws.log_group, "/aws-glue/jobs/custom/compass-sales-performance/error")
| filter contains(content, "skipping table", caseSensitive: false)
| fields timestamp, aws.log_group, content
| sort timestamp desc
| limit 1000
```

## 4. 4a) cs-digital-document-management — Error alerts

```dql
fetch logs
| filter contains(aws.log_group, "cs-digital-document-management") or contains(log.source, "cs-digital-document-management")
| filter contains(content, "error", caseSensitive: false)
| filter not contains(content, "elivery not possible", caseSensitive: false)
| fields timestamp, aws.log_group, content
| sort timestamp desc
| limit 1000
```

## 5. 4b) cs-digital-document-management — Claims API fails

```dql
fetch logs
| filter matchesValue(aws.log_group, "/aws/lambda/cs-digital-document-management-prod-*")
   or contains(aws.log_group, "/aws/lambda/cs-digital-document-management-prod-")
| filter contains(content, "claims api call failed", caseSensitive: false)
| fields timestamp, aws.log_group, content
| sort timestamp desc
| limit 1000
```

## 6. 5a) customer-process-api — Customer Process API Alerts

```dql
fetch logs
| filter contains(aws.log_group, "customer-process-api") or contains(log.source, "customer-process-api")
| filter contains(content, "Task timed out", caseSensitive: false)
   or contains(content, "An error occurred", caseSensitive: false)
   or contains(content, "Failed to handle: lifeJData", caseSensitive: false)
   or contains(content, "Got unex", caseSensitive: false)
| summarize takeFirst(timestamp), takeFirst(aws.log_group), by: { content }
| sort `takeFirst(timestamp)` desc
| limit 1000
```

## 7. 5b) customer-process-api — Success Request Monitoring

```dql
fetch logs
| filter contains(aws.log_group, "customer-process-api") or contains(log.source, "customer-process-api")
| filter contains(content, "\"statusCode\":201") or contains(content, "statusCode\":201")
| summarize takeFirst(timestamp), takeFirst(aws.log_group), by: { content }
| sort `takeFirst(timestamp)` desc
| limit 1000
```

## 8. 6a) document-upload-api — HasDetectedBatchError_High

```dql
fetch logs
| filter contains(aws.log_group, "/aws/lambda/document-upload-ap")
| filter contains(content, "Error Report", caseSensitive: false)
   or contains(content, "ExitError", caseSensitive: false)
| fields timestamp, aws.log_group, content
| sort timestamp desc
| limit 1000
```

## 9. 6b) document-upload-api — HasDetectedCMXErrors_High

```dql
fetch logs
| filter contains(aws.log_group, "/aws/lambda/document-upload-api-prod-")
| filter contains(content, "Failed to create CMX Documen", caseSensitive: false)
| fields timestamp, aws.log_group, content
| sort timestamp desc
| limit 1000
```

## 10. 6c) document-upload-api — HasDetectedDatabaseErrors_High

```dql
fetch logs
| filter contains(aws.log_group, "/aws/lambda/document-upload-api-prod-")
| filter contains(content, "Failed to init database", caseSensitive: false)
   or contains(content, "ETIM", caseSensitive: false)
| fields timestamp, aws.log_group, content
| sort timestamp desc
| limit 1000
```

## 11. 6d) document-upload — Failed Uploads

```dql
fetch logs
| filter contains(aws.log_group, "/aws/lambda/document-upload-api-prod-createDocumentAction")
| filter contains(content, "action:", caseSensitive: false)
| parse content, "LD 'action:' LD:action:string ', ' LD 'cmxDocumentId:' LD:cmxDocumentId:string"
| fields timestamp, aws.log_group, action, cmxDocumentId, content
| summarize takeFirst(timestamp), takeFirst(aws.log_group), by: { action, cmxDocumentId }
| limit 1000
```

## 12. 6e) document-upload — Pending Uploads

```dql
fetch logs
| filter contains(aws.log_group, "/aws/lambda/document-upload-api-prod-createDocumentAction")
| filter contains(content, "pending", caseSensitive: false)
   or contains(content, "action:", caseSensitive: false)
| fields timestamp, aws.log_group, content
| sort timestamp desc
| limit 1000
```

## 13. 7a) eopt-serverless — E-Tool Error Lambda

```dql
fetch logs
| filter contains(aws.log_group, "eopt-serverless") or contains(log.source, "eopt-serverless")
| filter matchesPhrase(content, "ERROR") or contains(content, "\tERROR") or contains(content, " ERROR")
| fields timestamp, aws.log_group, content
| sort timestamp desc
| limit 1000
```

## 14. 7b) eopt-serverless — AWS Serverless Error

```dql
fetch logs
| filter contains(aws.log_group, "eopt-serverless") or contains(log.source, "eopt-serverless")
| filter contains(content, "ERROR")
| fields timestamp, aws.log_group, content
| sort timestamp desc
| limit 1000
```

## 15. 8a) gov-inquiry-system — MDM file summary

```dql
fetch logs
| filter contains(aws.log_group, "/aws/lambda/gov-inquiry-system-prod-parseMdmResponseAndUpdateDb")
| filter contains(content, "Biz file summary", caseSensitive: false)
| filter contains(content, "fileCategory:MDM_SEARCH_RESULT_FILE")
   or contains(content, "MDM_SEARCH_RESULT_FILE")
| fields timestamp, content
| sort timestamp desc
| limit 500
```

## 16. 8b) gov-inquiry-system — ND file summary

```dql
fetch logs
| filter contains(aws.log_group, "/aws/lambda/gov-inquiry-system-prod-parseMdmResponseAndUpdateDb")
| filter contains(content, "Biz file summary", caseSensitive: false)
| filter contains(content, "NDM_SEARCH_RESULT_FILE") or contains(content, "ND_SEARCH_RESULT_FILE")
| fields timestamp, content
| sort timestamp desc
| limit 500
```

## 17. 8c) gov-inquiry-system — answer file summary (parseNdAndUpdateDb variant)

```dql
fetch logs
| filter contains(aws.log_group, "/aws/lambda/gov-inquiry-system-prod-parseNdAndUpdateDb")
| filter contains(content, "Biz file summary", caseSensitive: false)
| filter contains(content, "ND_SEARCH_RESULT_FILE")
| fields timestamp, content
| sort timestamp desc
| limit 500
```

## 18. 8d) gov-inquiry-system — answer file summary (buildAnswerFile / ANSWER_FILE)

```dql
fetch logs
| filter contains(aws.log_group, "/aws/lambda/gov-inquiry-system-prod-buildAnswerFile")
| filter contains(content, "Biz file summary", caseSensitive: false)
| filter contains(content, "fileCategory:ANSWER_FILE") or contains(content, "ANSWER_FILE")
| fields timestamp, content
| sort timestamp desc
| limit 500
```

## 19. 8e) gov-inquiry-system — request file summary

```dql
fetch logs
| filter contains(aws.log_group, "/aws/lambda/gov-inquiry-system-prod-validateAndComputeAnswer")
| filter contains(content, "Biz file summary", caseSensitive: false)
| filter contains(content, "fileCategory:REQUEST_FILE") or contains(content, "REQUEST_FILE")
| fields timestamp, content
| sort timestamp desc
| limit 500
```

## 20. 8f) gov-inquiry-system — General Error

```dql
fetch logs
| filter contains(aws.log_group, "/aws/lambda/gov-inquiry-system-prod-logFailure")
| filter contains(content, "level:ERROR", caseSensitive: false)
| fields timestamp, aws.log_group, content
| sort timestamp desc
| limit 1000
```

## 21. 8g) gov-inquiry-system — Pipitlinq Error File Processed

```dql
fetch logs
| filter contains(aws.log_group, "/aws/lambda/gov-inquiry-system-prod-parseErrorFileAndUpdateDb")
| filter contains(content, "ParseErrorFileAndUpdateDB", caseSensitive: false)
| fields timestamp, aws.log_group, content
| sort timestamp desc
| limit 1000
```

## 22. 8h) gov-inquiry-system — SYSERROR File Processed

```dql
fetch logs
| filter contains(aws.log_group, "/aws/lambda/gov-inquiry-system-prod-parseSysErrorFileAndUpdateDb")
| filter contains(content, "parseGatewaySysErrorFileAndUpdateDbEffect", caseSensitive: false)
| fields timestamp, aws.log_group, content
| sort timestamp desc
| limit 1000
```

## 23. 9) hpm-sharepoint-api

```dql
fetch logs
| filter contains(aws.log_group, "hpm-sharepoint-api") or contains(log.source, "hpm-sharepoint-api")
| filter contains(content, "ERROR", caseSensitive: false)
| fields timestamp, aws.log_group, content
| sort timestamp desc
| limit 1000
```

## 24. 10) hpm-survey-monkey

```dql
fetch logs
| filter contains(aws.log_group, "hpm-survey-monkey") or contains(log.source, "hpm-survey-monkey")
| filter contains(content, "ERROR", caseSensitive: false)
| fields timestamp, aws.log_group, content
| sort timestamp desc
| limit 1000
```

## 25. 11) innorules — BRE alert

```dql
fetch logs
| filter contains(aws.log_group, "innorules") or contains(log.source, "innorules")
| filter matchesPhrase(content, "ERROR") or contains(content, " ERROR")
| fields timestamp, aws.log_group, content
| sort timestamp desc
| limit 1000
```

## 26. 12) message-box-api — OverallMsgBoxErrors

```dql
fetch logs
| filter contains(aws.log_group, "message-box-api") or contains(log.source, "message-box-api")
| filter contains(content, "error", caseSensitive: false)
   or contains(content, "warn", caseSensitive: false)
| fields timestamp, aws.log_group, content
| sort timestamp desc
| limit 1000
```

## 27. 13a) myaxa — handleOnboardedCustomers error

```dql
fetch logs
| filter contains(aws.log_group, "myaxa-onboarding-batch") or contains(log.source, "myaxa-onboarding-batch")
| filter contains(content, "handleOnboardedCustomers")
| filter contains(content, "handleOnboardedCustomers :: error")
| fields timestamp, aws.log_group, content
| sort timestamp desc
| limit 1000
```

## 28. 13b) myaxa — email sending failed

```dql
fetch logs
| filter contains(aws.log_group, "myaxa-onboarding-batch") or contains(log.source, "myaxa-onboarding-batch")
| filter contains(content, "sendNotificationsQueueConsumer :: email sending failed")
| fields timestamp, aws.log_group, content
| sort timestamp desc
| limit 1000
```

## 29. 13c) myaxa — sendNotificationsQueueConsumer error

```dql
fetch logs
| filter contains(aws.log_group, "myaxa-onboarding-batch") or contains(log.source, "myaxa-onboarding-batch")
| filter contains(content, "sendNotificationsQueueConsumer :: error")
| fields timestamp, aws.log_group, content
| sort timestamp desc
| limit 1000
```

## 30. 13d) myaxa — message sending failed

```dql
fetch logs
| filter contains(aws.log_group, "myaxa-onboarding-batch") or contains(log.source, "myaxa-onboarding-batch")
| filter contains(content, "sendNotificationsQueueConsumer :: message sending failed")
| fields timestamp, aws.log_group, content
| sort timestamp desc
| limit 1000
```

## 31. 13e) myaxa — sendNotifications error

```dql
fetch logs
| filter contains(aws.log_group, "myaxa-onboarding-batch") or contains(log.source, "myaxa-onboarding-batch")
| filter contains(content, "sendNotifications :: error")
| fields timestamp, aws.log_group, content
| sort timestamp desc
| limit 1000
```

## 32. 14a) pmt-api — email sending error

```dql
fetch logs
| filter contains(aws.log_group, "pmt-api") or contains(log.source, "pmt-api")
| filter contains(content, "Error occured during email sending process for this user")
   or contains(content, "Error occurred during email sending process for this user")
| fields timestamp, aws.log_group, content
| sort timestamp desc
| limit 1000
```

## 33. 14b) pmt-api — Exception in ExportData

```dql
fetch logs
| filter contains(aws.log_group, "pmt-api") or contains(log.source, "pmt-api")
| filter contains(content, "Exception in ExportData")
| fields timestamp, aws.log_group, content
| sort timestamp desc
| limit 1000
```

## 34. 14c) pmt-api — Exception in myAxaMailSender

```dql
fetch logs
| filter contains(aws.log_group, "pmt-api") or contains(log.source, "pmt-api")
| filter contains(content, "Exception in myAxaMailSender")
| fields timestamp, aws.log_group, content
| sort timestamp desc
| limit 1000
```

## 35. 14d) pmt-api — Max Memory Used > 400

```dql
fetch logs
| filter contains(aws.log_group, "pmt-api") or contains(log.source, "pmt-api")
| filter contains(content, "Max Memory Used")
| parse content, "LD 'Used:' SPACE? LD:MemoryUsage:long"
| filter MemoryUsage > 400
| fields timestamp, aws.log_group, MemoryUsage, content
| sort timestamp desc
| limit 1000
```

## 36. 14e) pmt-api — Max Memory Used > 480

```dql
fetch logs
| filter contains(aws.log_group, "pmt-api") or contains(log.source, "pmt-api")
| filter contains(content, "Max Memory Used")
| parse content, "LD 'Used:' SPACE? LD:MemoryUsage:long"
| filter MemoryUsage > 480
| fields timestamp, aws.log_group, MemoryUsage, content
| sort timestamp desc
| limit 1000
```

## 37. 14f) pmt-api — SendApprovalReminder failed

```dql
fetch logs
| filter contains(aws.log_group, "pmt-api") or contains(log.source, "pmt-api")
| filter contains(content, "SendApprovalReminder handler failed")
| fields timestamp, aws.log_group, content
| sort timestamp desc
| limit 1000
```

## 38. 14g) pmt-api — Transformation Timeout

```dql
fetch logs
| filter contains(aws.log_group, "pmt-api") or contains(log.source, "pmt-api")
| filter contains(content, "Task timed out")
| fields timestamp, aws.log_group, content
| sort timestamp desc
| limit 1000
```

## 39. 14h) pmt-api — Unexpected Error exclude Sfdc

```dql
fetch logs
| filter contains(aws.log_group, "pmt-api") or contains(log.source, "pmt-api")
| filter contains(content, "Unexpected error", caseSensitive: false)
| filter not contains(content, "Sfdc", caseSensitive: false)
| filter not contains(content, "sfdc", caseSensitive: false)
| fields timestamp, aws.log_group, content
| sort timestamp desc
| limit 1000
```

## 40. 14i) pmt-api — SFDC API Error

```dql
fetch logs
| filter contains(aws.log_group, "pmt-api") or contains(log.source, "pmt-api")
| filter contains(content, "An error occurred while calling sfdc api", caseSensitive: false)
| fields timestamp, aws.log_group, content
| sort timestamp desc
| limit 1000
```

## 41. 15a) recruitimp — RI Monitoring Error

```dql
fetch logs
| filter contains(aws.log_group, "recruitimp-serverless") or contains(log.source, "recruitimp-serverless")
| filter contains(content, "\tERROR") or matchesPhrase(content, "ERROR")
| fields timestamp, aws.log_group, content
| sort timestamp desc
| limit 1000
```

## 42. 15b) recruitimp — AWS Serverless Error

```dql
fetch logs
| filter contains(aws.log_group, "recruitimp-serverless") or contains(log.source, "recruitimp-serverless")
| filter contains(content, "level:ERROR", caseSensitive: false)
   or contains(content, "level:error", caseSensitive: false)
| fields timestamp, aws.log_group, content
| sort timestamp desc
| limit 1000
```

## 43. 16a) sa-support — Error

```dql
fetch logs
| filter contains(aws.log_group, "sa-support-batches") or contains(log.source, "sa-support-batches")
| filter contains(content, "error", caseSensitive: false)
| fields timestamp, aws.log_group, content
| sort timestamp desc
| limit 1000
```

## 44. 16b) sa-support — File Import Confirmation

```dql
fetch logs
| filter contains(aws.log_group, "sa-support-batches") or contains(log.source, "sa-support-batches")
| filter contains(content, "importFileHandler :: runner :")
   or contains(content, "importSagaFundGroup")
   or contains(content, "started")
| fields timestamp, aws.log_group, content
| sort timestamp desc
| limit 1000
```

## 45. 16c) sa-support — Task Time Out

```dql
fetch logs
| filter contains(aws.log_group, "sa-support-batches") or contains(log.source, "sa-support-batches")
| filter contains(content, "Task timed out", caseSensitive: false)
| fields timestamp, aws.log_group, content
| sort timestamp desc
| limit 1000
```

## Related files

| File | Role |
| --- | --- |
| `6-all-dynatrace-queries.md` | This file |
| `5-all-splunk-alerts-to-dql.dql` | Plain DQL companion |
