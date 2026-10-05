# IWFM Alerts Glossary

| Term | What it means | Why you care |
|---|---|---|
| IWFM | Backend workflow and forms system that EIP006 and Compass depend on | All three alerts watch it from different sides |
| EIP mediator | Integration layer that calls backend services | EIP006 failures show IWFM trouble from the caller side |
| `transaction` | Splunk command that groups related lines into one event | Here it only groups lines within 1 second, so it adds nothing |
| `arrayMovingSum(count, 5)` | Rolling 5-minute total from per-minute counts | Matches "more than 15 in 5 minutes" |
| Dealerting samples | Quiet minutes before the problem closes | 60 copies the 1-hour throttle |
| `caseSensitive: false` | Makes DQL contains ignore case | Splunk ignores case by default |
