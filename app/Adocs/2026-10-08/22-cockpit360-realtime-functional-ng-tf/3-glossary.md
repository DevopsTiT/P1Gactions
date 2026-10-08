# Cockpit360 NG Glossary

| Term | What it means | Why you care |
|---|---|---|
| jenkins_statistics | Splunk index with Jenkins build events | Source for this alert |
| json:jenkins:old | Sourcetype of those events | Same JSON keys as seq 12 |
| group-jobs | Real Time group job | Its result decides OK or NG |
| applications | Functional job | Grouped with the Real Time job |
| tempname | Name in "Building ..." text of a group job | Links Real Time to Functional |
| » | Jenkins folder separator in build logs | Turned into "/" to match job_name |
| OKメンテナンス中 | "OK, under maintenance" remark | Shown on the problem as remarks |
