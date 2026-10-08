# PDDW0100 Claims Status Result

| Item | Value |
|---|---|
| Resource | pddw0100_claims_status |
| Fires when | A PDDW run's latest snapshot is not Ended OK, from 08:15 JST |
| Identity | odate + order_id |
| Severity | high |
| PagerDuty | "0" |
| Clean up | Remove 10-07 seq 14 pddw_no_success if applied |
