# CompassPB and PD Fix Glossary

| Term | What it means | Why you care |
|---|---|---|
| Resource name | Terraform's ID for a detector | Two folders with the same name manage the same detector |
| In-place update | Apply changes the existing detector instead of creating a new one | The last folder applied wins |
| pagerduty.enabled | Our flag that routes the problem to PagerDuty | "0" means nobody gets paged |
| OKメンテナンス中 | Log text meaning "OK, under maintenance" | Shown as remarks on CompassPB problems |
