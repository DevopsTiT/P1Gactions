# Investigation

| Check | Result |
| --- | --- |
| User ask | scope different? what should Splunk query transfer to? |
| Splunk | index=cs-digital-document-management + error + exclude elivery |
| DQL attempt | aws.log_group …-prod only + content filters |
| Verdict | Yes scope differ; widen/discover then same content logic |
| Seq | 4 on 2026-09-24 |
