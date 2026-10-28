# Pic

```
Business Requirements (2/4)
  |
  +-- 4 Capability
  |     [X] Other workplace assistants
  |     [X] Other: Teams catch-up after the incident exists
  |     document / claims / sales / code boxes stay blank
  |
  +-- AXA Japan
  |     [X] Yes — Dynatrace + Splunk already detect
  |     architect line → still open
  |
  +-- Group library
  |     [ ] Yes — search the library before the meeting
  |
  +-- 5 Value
        catch-up in Teams
        status draft
        bridge note
        late joiner reads one reply
        Dynatrace and Splunk still detect
        PagerDuty still pages
        Silva still holds correlation
```

```
[Detectors] → [PagerDuty page] → [Teams ask]
                                      |
                                      v
                               shared catch-up
                                      |
                                      v
                          person confirms, then acts
                                      |
                                      v
                              [ServiceNow / Silva]
```
