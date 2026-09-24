# All Dynatrace Query Transfers

```
Style (from your editor)
  N) service-name
  Alert name: ...
  <Splunk query>
  <Dynatrace DQL>
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| Pattern | Prefer `contains(aws.log_group, "/aws/lambda/<app>")` like your cmx example |
| Splunk first | Each block keeps the original Splunk line |
| Glue / special | Use real log group path (not always `/aws/lambda/`) |
| Scope tip | If few rows, widen to index name or run Discover |

## Summary

All Splunk alerts from `1 copy.sh` transferred to Dynatrace DQL in the same layout as your `cmx-sharepoint-api` block.

## Discover helper

```dql
fetch logs
| filter contains(aws.log_group, "<index-or-app>") or contains(log.source, "<index-or-app>")
| summarize count = count(), by: { aws.log_group, log.source }
| sort count desc
| limit 50
```

---

## 1) cci-fa-comm-calc

Alert name: `CCI_AWS_Batch Time Out`

```spl
index=cci-fa-comm-calc "Task timed out"
| search message!="!DEBUG!"
```

```dql
fetch logs
| filter contains(aws.log_group, "/aws/lambda/cci-fa-comm-calc") or contains(aws.log_group, "cci-fa-comm-calc")
| filter contains(content, "Task timed out", caseSensitive: false)
| filter not contains(content, "!DEBUG!")
```

---

## 2) cmx-sharepoint-api

Alert name: `Prod_Life_HPM_CMXtoSharepoint_APILambdaError_Normal`

```spl
index="cmx-sharepoint-api" message="*Error*"
```

```
# fetch logs
# | filter log.source == "cmx-sharepoint-api"
# | filter matchesPhrase(content, "Error")
```

```dql
fetch logs
| filter contains(aws.log_group, "/aws/lambda/cmx-sharepoint-api")
| filter contains(content, "Error", caseSensitive: false)
```

Optional check (your style — info lines):

```dql
fetch logs
| filter contains(aws.log_group, "/aws/lambda/cmx-sharepoint-api")
| filter contains(content, "info", caseSensitive: false)
```

---

## 3) compass-sales-performance

Alert name: `Prod_Life_Compass_BigData連動Glue_Skip発生`

```spl
index="compass-sales" logGroup="/aws-glue/jobs/custom/compass-sales-performance/error" message="*skipping table*"
```

```
# Not Lambda — AWS Glue error log group
```

```dql
fetch logs
| filter contains(aws.log_group, "/aws-glue/jobs/custom/compass-sales-performance/error")
| filter contains(content, "skipping table", caseSensitive: false)
```

Wider if few rows:

```dql
fetch logs
| filter contains(aws.log_group, "compass-sales-performance") or contains(aws.log_group, "compass-sales")
| filter contains(content, "skipping table", caseSensitive: false)
```

---

## 4) cs-digital-document-management

### 4a

Alert name: `CS Digital Document Management Error alerts`

```spl
index="cs-digital-document-management" "error"
| search message="*error*" AND message!="*elivery not possible*"
```

```dql
fetch logs
| filter contains(aws.log_group, "/aws/lambda/cs-digital-document-management") or contains(aws.log_group, "cs-digital-document-management")
| filter contains(content, "error", caseSensitive: false)
| filter not contains(content, "elivery not possible", caseSensitive: false)
```

### 4b

Alert name: `[CSDDM] Send alert email when Claims API fails`

```spl
index="cs-digital-document-management"
| spath logGroup
| search logGroup="/aws/lambda/cs-digital-document-management-prod-*"
| search message="*claims api call failed*"
```

```dql
fetch logs
| filter contains(aws.log_group, "/aws/lambda/cs-digital-document-management-prod-")
| filter contains(content, "claims api call failed", caseSensitive: false)
```

---

## 5) customer-process-api

### 5a

Alert name: `Customer Process API Alerts`

```spl
index=customer-process-api
| search message="*Task timed out*" OR message="*An error occurred*" OR message="*Failed to handle: lifeJData*" OR message="*Got unex*"
| dedup message
| table _time logGroup message
```

```
# TODO: confirm full "Got unexpected ..." from source file (screenshot truncated)
```

```dql
fetch logs
| filter contains(aws.log_group, "/aws/lambda/customer-process-api") or contains(aws.log_group, "customer-process-api")
| filter contains(content, "Task timed out", caseSensitive: false)
   or contains(content, "An error occurred", caseSensitive: false)
   or contains(content, "Failed to handle: lifeJData", caseSensitive: false)
   or contains(content, "Got unex", caseSensitive: false)
```

### 5b

Alert name: `Customer Process API Success Request Monitoring`

```spl
index=customer-process-api
| search message="*\"statusCode\":201*"
| dedup message
| table _time logGroup message
```

```dql
fetch logs
| filter contains(aws.log_group, "/aws/lambda/customer-process-api") or contains(aws.log_group, "customer-process-api")
| filter contains(content, "\"statusCode\":201") or contains(content, "statusCode\":201")
```

---

## 6) document-upload-api

### 6a

Alert name: `Prod_Life_CDUS_Backend HasDetectedBatchError_High`

```spl
index=document-upload-api "Error Report" OR "ExitError"
| spath logGroup
| search logGroup="/aws/lambda/document-upload-ap*"
```

```
# TODO: confirm full logGroup suffix from source
```

```dql
fetch logs
| filter contains(aws.log_group, "/aws/lambda/document-upload-ap")
| filter contains(content, "Error Report", caseSensitive: false)
   or contains(content, "ExitError", caseSensitive: false)
```

### 6b

Alert name: `Prod_Life_CDUS_Backend HasDetectedCMXErrors_High`

```spl
index=document-upload-api
| spath logGroup
| search logGroup="/aws/lambda/document-upload-api-prod-*" "Failed to create CMX Documen*"
```

```dql
fetch logs
| filter contains(aws.log_group, "/aws/lambda/document-upload-api-prod-")
| filter contains(content, "Failed to create CMX Documen", caseSensitive: false)
```

### 6c

Alert name: `Prod_Life_CDUS_Backend HasDetectedDatabaseErrors_High`

```spl
index=document-upload-api
| spath logGroup
| search logGroup="/aws/lambda/document-upload-api-prod-*" "Failed to init database" ETIM*
```

```dql
fetch logs
| filter contains(aws.log_group, "/aws/lambda/document-upload-api-prod-")
| filter contains(content, "Failed to init database", caseSensitive: false)
   or contains(content, "ETIM", caseSensitive: false)
```

### 6d

Alert name: `Prod_Life_CDUS_Backend HasDetectedFailedUploads_High`

```spl
index=document-upload-api
| spath logGroup
| search logGroup="/aws/lambda/document-upload-api-prod-createDocumentAction"
| rex "action:(?<action>[a-zA-Z_]*).*?cmxDocumentId:(?<cmxDocumentId>[^,\s]*)"
| table action cmxDocumentId
| dedup action cmxDocumentId
```

```dql
fetch logs
| filter contains(aws.log_group, "/aws/lambda/document-upload-api-prod-createDocumentAction")
| filter contains(content, "action:", caseSensitive: false)
| filter contains(content, "cmxDocumentId:", caseSensitive: false)
```

### 6e

Alert name: `Prod_Life_CDUS_Backend HasDetectedPendingUploads_High`

```spl
index=document-upload-api
| spath logGroup
| search logGroup="/aws/lambda/document-upload-api-prod-createDocumentAction"
| rex "action:(?<action>[a-zA-Z_]*).*?cmxDocumentId:(?<cmxDocumentId>[^,\s]*)"
| table action cmxDocumentId
| dedup action cmxDocumentId
```

```
# TODO: add pending-specific filter from full Splunk if different from 6d
```

```dql
fetch logs
| filter contains(aws.log_group, "/aws/lambda/document-upload-api-prod-createDocumentAction")
| filter contains(content, "pending", caseSensitive: false)
   or contains(content, "action:", caseSensitive: false)
```

---

## 7) eopt-serverless

### 7a

Alert name: `E-Tool Error Lambda`

```spl
index="eopt-serverless"
| rex field=message "\w+\-\w+\-\w+\-\w+\-\w+.*?(?P<level>\w+)"
| table _time level message
| where level="ERROR"
```

```dql
fetch logs
| filter contains(aws.log_group, "/aws/lambda/eopt-serverless") or contains(aws.log_group, "eopt-serverless")
| filter contains(content, "ERROR")
```

### 7b

Alert name: `eopt - AWS Serverless Error`

```spl
index="eopt-serverless"
| rex field=message "\w+\-\w+\-\w+\-\w+\-\w+.*?(?P<level>\w+)"
| search level="ERROR"
```

```dql
fetch logs
| filter contains(aws.log_group, "/aws/lambda/eopt-serverless") or contains(aws.log_group, "eopt-serverless")
| filter contains(content, "ERROR")
```

---

## 8) gov-inquiry-system

### 8a

Alert name: `[gov-inquiry-system] MDM file summary`

```spl
index=gov-inquiry-system
| search logGroup="/aws/lambda/gov-inquiry-system-prod-parseMdmResponseAndUpdateDb"
| search message="*Biz file summary*"
| rex field=message "fileCategory:(?<fileCategory>[^, ]+)"
| search fileCategory="MDM_SEARCH_RESULT_FILE"
```

```dql
fetch logs
| filter contains(aws.log_group, "/aws/lambda/gov-inquiry-system-prod-parseMdmResponseAndUpdateDb")
| filter contains(content, "Biz file summary", caseSensitive: false)
| filter contains(content, "MDM_SEARCH_RESULT_FILE")
```

### 8b

Alert name: `[gov-inquiry-system] ND file summary`

```spl
index=gov-inquiry-system
| search logGroup="/aws/lambda/gov-inquiry-system-prod-parseMdmResponseAndUpdateDb"
| search message="*Biz file summary*"
| search fileCategory="NDM_SEARCH_RESULT_FILE"
```

```dql
fetch logs
| filter contains(aws.log_group, "/aws/lambda/gov-inquiry-system-prod-parseMdmResponseAndUpdateDb")
| filter contains(content, "Biz file summary", caseSensitive: false)
| filter contains(content, "NDM_SEARCH_RESULT_FILE") or contains(content, "ND_SEARCH_RESULT_FILE")
```

### 8c

Alert name: `[gov-inquiry-system] answer file summary` (parseNdAndUpdateDb)

```spl
index=gov-inquiry-system
| search logGroup="/aws/lambda/gov-inquiry-system-prod-parseNdAndUpdateDb"
| search message="*Biz file summary*"
| search fileCategory="ND_SEARCH_RESULT_FILE"
```

```dql
fetch logs
| filter contains(aws.log_group, "/aws/lambda/gov-inquiry-system-prod-parseNdAndUpdateDb")
| filter contains(content, "Biz file summary", caseSensitive: false)
| filter contains(content, "ND_SEARCH_RESULT_FILE")
```

### 8d

Alert name: `[gov-inquiry-system] answer file summary` (buildAnswerFile)

```spl
index=gov-inquiry-system
| search logGroup="/aws/lambda/gov-inquiry-system-prod-buildAnswerFile"
| search message="*Biz file summary*"
| search fileCategory="ANSWER_FILE"
```

```dql
fetch logs
| filter contains(aws.log_group, "/aws/lambda/gov-inquiry-system-prod-buildAnswerFile")
| filter contains(content, "Biz file summary", caseSensitive: false)
| filter contains(content, "ANSWER_FILE")
```

### 8e

Alert name: `[gov-inquiry-system] request file summary`

```spl
index=gov-inquiry-system
| search logGroup="/aws/lambda/gov-inquiry-system-prod-validateAndComputeAnswer"
| search message="*Biz file summary*"
| search fileCategory="REQUEST_FILE"
```

```dql
fetch logs
| filter contains(aws.log_group, "/aws/lambda/gov-inquiry-system-prod-validateAndComputeAnswer")
| filter contains(content, "Biz file summary", caseSensitive: false)
| filter contains(content, "REQUEST_FILE")
```

### 8f

Alert name: `gov-inquiry-system General Error`

```spl
index=gov-inquiry-system
| search logGroup="/aws/lambda/gov-inquiry-system-prod-logFailure"
| search message="*level:ERROR*"
```

```dql
fetch logs
| filter contains(aws.log_group, "/aws/lambda/gov-inquiry-system-prod-logFailure")
| filter contains(content, "level:ERROR", caseSensitive: false)
```

### 8g

Alert name: `gov-inquiry-system Pipitlinq Error File Processed`

```spl
index=gov-inquiry-system
| search logGroup="/aws/lambda/gov-inquiry-system-prod-parseErrorFileAndUpdateDb"
| search message="*ParseErrorFileAndUpdateDB*"
```

```dql
fetch logs
| filter contains(aws.log_group, "/aws/lambda/gov-inquiry-system-prod-parseErrorFileAndUpdateDb")
| filter contains(content, "ParseErrorFileAndUpdateDB", caseSensitive: false)
```

### 8h

Alert name: `gov-inquiry-system SYSERROR File Processed`

```spl
index=gov-inquiry-system
| search logGroup="/aws/lambda/gov-inquiry-system-prod-parseSysErrorFileAndUpdateDb"
| search message="*parseGatewaySysErrorFileAndUpdateDbEffect*"
```

```dql
fetch logs
| filter contains(aws.log_group, "/aws/lambda/gov-inquiry-system-prod-parseSysErrorFileAndUpdateDb")
| filter contains(content, "parseGatewaySysErrorFileAndUpdateDbEffect", caseSensitive: false)
```

---

## 9) hpm-sharepoint-api

Alert name: `Prod_Life_HPM_SharepointAPILambdaError_Normal`

```spl
index="hpm-sharepoint-api" message="*ERROR*"
```

```dql
fetch logs
| filter contains(aws.log_group, "/aws/lambda/hpm-sharepoint-api")
| filter contains(content, "ERROR", caseSensitive: false)
```

---

## 10) hpm-survey-monkey

Alert name: `Prod_Life_HPM_SurveyMonkeyLambdaError_Normal`

```spl
index="hpm-survey-monkey" message="*ERROR*"
```

```dql
fetch logs
| filter contains(aws.log_group, "/aws/lambda/hpm-survey-monkey")
| filter contains(content, "ERROR", caseSensitive: false)
```

---

## 11) innorules

Alert name: `BRE alert`

```spl
index="innorules"
| rex field=message "^(.*?)\s+){2}(?P<loglevel>\w+)\s+"
| where loglevel="ERROR"
```

```dql
fetch logs
| filter contains(aws.log_group, "/aws/lambda/innorules") or contains(aws.log_group, "innorules")
| filter contains(content, "ERROR")
```

---

## 12) message-box-api

Alert name: `Prod_Life_Emma_OverallMsgBoxErrors_Normal`

```spl
index=message-box-api error OR warn
| rex field=message "(?P<loglevel>\w+)"
| search loglevel=error OR loglevel=warn
| table _time loglevel *
```

```dql
fetch logs
| filter contains(aws.log_group, "/aws/lambda/message-box-api") or contains(aws.log_group, "message-box-api")
| filter contains(content, "error", caseSensitive: false)
   or contains(content, "warn", caseSensitive: false)
```

---

## 13) myaxa-onboarding-batch

### 13a

Alert name: `Prod_Life_Emma_myaxa-onboarding-batch_handleOnboardedCustomers_error_High`

```spl
index="myaxa-onboarding-batch" "handleOnboardedCustomers" "handleOnboardedCustomers :: error"
```

```dql
fetch logs
| filter contains(aws.log_group, "/aws/lambda/myaxa-onboarding-batch") or contains(aws.log_group, "myaxa-onboarding-batch")
| filter contains(content, "handleOnboardedCustomers :: error")
```

### 13b

Alert name: `Prod_Life_Emma_myaxa-onboarding-batch_sendNotificationsQueueConsumer_email_sending_failed_High`

```spl
index="myaxa-onboarding-batch" "sendNotificationsQueueConsumer :: email sending failed"
```

```dql
fetch logs
| filter contains(aws.log_group, "/aws/lambda/myaxa-onboarding-batch") or contains(aws.log_group, "myaxa-onboarding-batch")
| filter contains(content, "sendNotificationsQueueConsumer :: email sending failed")
```

### 13c

Alert name: `Prod_Life_Emma_myaxa-onboarding-batch_sendNotificationsQueueConsumer_error_High`

```spl
index="myaxa-onboarding-batch" "sendNotificationsQueueConsumer :: error"
```

```dql
fetch logs
| filter contains(aws.log_group, "/aws/lambda/myaxa-onboarding-batch") or contains(aws.log_group, "myaxa-onboarding-batch")
| filter contains(content, "sendNotificationsQueueConsumer :: error")
```

### 13d

Alert name: `Prod_Life_Emma_myaxa-onboarding-batch_sendNotificationsQueueConsumer_message_sending_failed_High`

```spl
index="myaxa-onboarding-batch" "sendNotificationsQueueConsumer :: message sending failed"
```

```dql
fetch logs
| filter contains(aws.log_group, "/aws/lambda/myaxa-onboarding-batch") or contains(aws.log_group, "myaxa-onboarding-batch")
| filter contains(content, "sendNotificationsQueueConsumer :: message sending failed")
```

### 13e

Alert name: `Prod_Life_Emma_myaxa-onboarding-batch_sendNotifications_error_High`

```spl
index="myaxa-onboarding-batch" "sendNotifications :: error"
```

```dql
fetch logs
| filter contains(aws.log_group, "/aws/lambda/myaxa-onboarding-batch") or contains(aws.log_group, "myaxa-onboarding-batch")
| filter contains(content, "sendNotifications :: error")
```

---

## 14) pmt-api

### 14a

Alert name: `Error occurred during email sending process for this user`

```spl
index=pmt-api "Error occured during email sending process for this user"
| table _time logGroup message
```

```dql
fetch logs
| filter contains(aws.log_group, "/aws/lambda/pmt-api") or contains(aws.log_group, "pmt-api")
| filter contains(content, "Error occured during email sending process for this user")
   or contains(content, "Error occurred during email sending process for this user")
```

### 14b

Alert name: `Exception in ExportData for Datalake`

```spl
index=pmt-api "Exception in ExportData"
| table _time logGroup message
```

```dql
fetch logs
| filter contains(aws.log_group, "/aws/lambda/pmt-api") or contains(aws.log_group, "pmt-api")
| filter contains(content, "Exception in ExportData")
```

### 14c

Alert name: `Exception in myAxaMailSender` / `Prod_Life_Emma_ExceptionInMyAxaMailSender_Normal`

```spl
index=pmt-api "Exception in myAxaMailSender"
| table _time logGroup message
```

```dql
fetch logs
| filter contains(aws.log_group, "/aws/lambda/pmt-api") or contains(aws.log_group, "pmt-api")
| filter contains(content, "Exception in myAxaMailSender")
```

### 14d

Alert name: `STP APIs Memory Usage over 400MB`

```spl
index=pmt-api "Max Memory Used"
| search message="*Max Memory Used*"
| rex field=message "^.*?Used:\s(?P<MemoryUsage>\d+)"
| where MemoryUsage > 400
| table log_group, MemoryUsage, message
```

```dql
fetch logs
| filter contains(aws.log_group, "/aws/lambda/pmt-api") or contains(aws.log_group, "pmt-api")
| filter contains(content, "Max Memory Used")
| parse content, "LD 'Used:' SPACE? LD:MemoryUsage:long"
| filter MemoryUsage > 400
```

### 14e

Alert name: `STP APIs Memory Usage over 480MB`

```spl
index=pmt-api "Max Memory Used"
| search message="*Max Memory Used*"
| rex field=message "^.*?Used\:\s(?P<MemoryUsage>\d+)"
| where MemoryUsage > 480
| table log_group, MemoryUsage, message
```

```dql
fetch logs
| filter contains(aws.log_group, "/aws/lambda/pmt-api") or contains(aws.log_group, "pmt-api")
| filter contains(content, "Max Memory Used")
| parse content, "LD 'Used:' SPACE? LD:MemoryUsage:long"
| filter MemoryUsage > 480
```

### 14f

Alert name: `SendApprovalReminder handler failed`

```spl
index=pmt-api "SendApprovalReminder handler failed"
```

```dql
fetch logs
| filter contains(aws.log_group, "/aws/lambda/pmt-api") or contains(aws.log_group, "pmt-api")
| filter contains(content, "SendApprovalReminder handler failed")
```

### 14g

Alert name: `Transformation Timeout`

```spl
index=pmt-api "Task timed out"
```

```dql
fetch logs
| filter contains(aws.log_group, "/aws/lambda/pmt-api") or contains(aws.log_group, "pmt-api")
| filter contains(content, "Task timed out")
```

### 14h

Alert name: `Unexpected Error`

```spl
index=pmt-api "Unexpected error*"
| search message!="*$fdc*"
| table _time logGroup message
```

```dql
fetch logs
| filter contains(aws.log_group, "/aws/lambda/pmt-api") or contains(aws.log_group, "pmt-api")
| filter contains(content, "Unexpected error", caseSensitive: false)
| filter not contains(content, "Sfdc", caseSensitive: false)
| filter not contains(content, "sfdc", caseSensitive: false)
```

### 14i

Alert name: `pmt-api SFDC Error`

```spl
index=pmt-api "An error occurred while calling sfdc api"
```

```dql
fetch logs
| filter contains(aws.log_group, "/aws/lambda/pmt-api") or contains(aws.log_group, "pmt-api")
| filter contains(content, "An error occurred while calling sfdc api", caseSensitive: false)
```

---

## 15) recruitimp-serverless

### 15a

Alert name: `RI Monitoring Error`

```spl
index=recruitimp-serverless
| rex field=message "(?P<sessionid>\w+\-\w+\-\w+\-\w+\-\w+)"
| rex field=message "\w+\-\w+\-\w+\-\w+\-\w+\t(?P<loglevel>\w+)\s+"
| rex field=message "\[(?P<userid>.*?)\]"
| where loglevel="ERROR"
| table _time loglevel logGroup message
```

```dql
fetch logs
| filter contains(aws.log_group, "/aws/lambda/recruitimp-serverless") or contains(aws.log_group, "recruitimp-serverless")
| filter contains(content, "ERROR")
```

### 15b

Alert name: `recruitimp - AWS Serverless Error`

```spl
index="recruitimp-serverless"
| rex field=message "level:(?P<level>[^,]+)+"
| eval severity = upper(level)
| search severity="ERROR"
```

```dql
fetch logs
| filter contains(aws.log_group, "/aws/lambda/recruitimp-serverless") or contains(aws.log_group, "recruitimp-serverless")
| filter contains(content, "level:ERROR", caseSensitive: false)
   or contains(content, "level:error", caseSensitive: false)
```

---

## 16) sa-support-batches

### 16a

Alert name: `Sa Support Batch Error`

```spl
index=sa-support-batches error
```

```dql
fetch logs
| filter contains(aws.log_group, "/aws/lambda/sa-support-batches") or contains(aws.log_group, "sa-support-batches")
| filter contains(content, "error", caseSensitive: false)
```

### 16b

Alert name: `Sa Support Batch File Import Confirmation`

```spl
index=sa-support-batches
| search message="*importFileHandler :: runner : *" OR message="*importSagaFundGroup*" OR message="*started*"
```

```dql
fetch logs
| filter contains(aws.log_group, "/aws/lambda/sa-support-batches") or contains(aws.log_group, "sa-support-batches")
| filter contains(content, "importFileHandler :: runner :")
   or contains(content, "importSagaFundGroup")
   or contains(content, "started")
```

### 16c

Alert name: `Sa Support Batch Task Time Out`

```spl
index=sa-support-batches
| search message="*Task timed out*"
```

```dql
fetch logs
| filter contains(aws.log_group, "/aws/lambda/sa-support-batches") or contains(aws.log_group, "sa-support-batches")
| filter contains(content, "Task timed out", caseSensitive: false)
```

---

## Data flow map

```
Your editor style (cmx example)
  → Alert name + Splunk
  → DQL: aws.log_group path + content filter
  → this MD (sections 1–16)
```

## Related files

| File | Role |
| --- | --- |
| `7-all-dynatrace-query-transfers.md` | This pack (your style) |
| `6-all-dynatrace-queries.md` | Earlier numbered-only pack |
| `5-all-splunk-alerts-to-dql.dql` | Plain `.dql` companion |
| `7.sh` | Optional helpers |

## Commands

See `7.sh`.
