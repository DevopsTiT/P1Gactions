# Result

| Step | Do this |
|---|---|
| 1 | Run the Step 1 DQL to find the bucket and fields for the ASA logs |
| 2 | Create a static threshold custom alert: threshold 3, Above, sliding window 1, violating samples 1, dealerting 5 |
| 3 | Use the same title and description as Splunk |
| 4 | Agree the SILVA team and PagerDuty severity, then add them to the workflow for this event name |
| 5 | Test with a temporary threshold of 0 or 4 synthetic syslog lines in one minute |
| 6 | Turn off the Splunk alert only after Dynatrace has fired correctly once |
