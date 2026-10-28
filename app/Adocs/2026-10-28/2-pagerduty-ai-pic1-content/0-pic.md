# Pic

```
Business Requirements (1/4)
  |
  +-- 1 Value Chain
  |     [X] Information technology
  |     [X] Operational Excellence and Project Management
  |     [X] Data & AI
  |
  +-- 2 Current process (before AI)
  |     Use case 1: Dynatrace -> PagerDuty page -> Teams post
  |                 -> Primary acks -> hand catch-up -> hand status
  |     Use case 2: late joiner reads Teams + PagerDuty + Dynatrace
  |
  +-- 3 Pains
        time to rebuild the timeline
        too much data to read by hand
        chat notes stay off the incident
        on-call time spent on copy-paste
        thin handoff
        keep paging
        keep Teams notify
        keep Dynatrace as the detector
```

```
[Dynatrace problem]
      |
      v
[PagerDuty incident] --page--> [Primary]
      |
      +--post--> [Teams channel]
                      |
                      v
            hand catch-up / hand status / hand PIR
```
