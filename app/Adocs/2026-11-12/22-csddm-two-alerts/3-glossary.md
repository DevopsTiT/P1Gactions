# Glossary

| Term | What it means |
|---|---|
| spath logGroup | Splunk reads the log group out of the event. The query uses aws.log.group. |
| prod-* | Any prod function whose log group starts with that path. |
| message!="*error*" | The message field must not contain error. |
| *elivery not possible* | The visible exclusion. It also matches delivery not possible. |
| ALJ_CLAIMS | Prefix for the Claims API alert only. |
| ALJ_CSDDM | Prefix for the document management error alert only. |
