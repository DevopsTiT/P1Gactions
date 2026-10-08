# HPM Hourly NG Glossary

| Term | What it means | Why you care |
|---|---|---|
| Cron 0 * * * * | Run at minute 0 of every hour | This alert runs hourly |
| Expires | How long Splunk keeps the triggered alert record | 1 hour here |
| Duplicate alert | Two alerts with the same search | Only one detector is needed in Dynatrace |
| enabled = false | Terraform creates the detector switched off | Keeps the option without double alerts |
| Notification workflow | Dynatrace automation that sends mail or pages | Can add hourly reminders instead of a second detector |
