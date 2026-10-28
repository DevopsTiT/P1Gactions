# Pic

```
Page 4
  |
  +-- 7 Users
  |     [X] Employees
  |     [X] Support Function
  |     Technology DevOps + Application Support
  |     headcount = count the rota
  |
  +-- Consumers
  |     [X] Employees
  |     BAM-India, DBA, Network, Axa GO, Cloud Broker, status readers
  |
  +-- 8 Success
  |     Teams connected
  |     reply on a test incident
  |     5 reviewed incidents match PagerDuty
  |     person sends the status
  |     page still works if the assist is down
  |
  +-- 9 Downtime
        4 hours for the Teams reply
        call / SMS / escalation stay on current PagerDuty
```

```
[On-call asks in Teams] → [AI reply] → [reviewer checks PagerDuty]
        |
        +-- assist down ≤ 4h → manual catch-up
        |
        v
[PagerDuty call / SMS] keeps running
```
