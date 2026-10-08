# CCI Goal Management Investigation

| What I checked | What I found |
|---|---|
| Index and source | jenkins, jenkins/test (build_report events). |
| name logic | Built from source, so it is always "jenkins/test". |
| status field | Not in build_report events, so Response_Code is empty. |
| Lookup | No match, so application is "-". |
| Result | Status is always NG; the alert is stuck. |
| Actions | Triggered Alerts and Alert Status Manager on Production, PagerDuty Disable. |
