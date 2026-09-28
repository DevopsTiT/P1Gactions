# Example Fields And Testing Group Map

## Decision tree

```
Test ticket created?
 group = testing 3122?          yes → routing override works
                                no  → check notFilled; group name must match exactly
 fields match example?          check notFilled list in post-silva-incident-http result
 ready for real alerts?         set TEST_ASSIGNMENT_GROUP = "" → AGO_AXA_SUPPORTGROUP tag decides
```

## Data flow

```
Problem ACTIVE → prepare-payload (example constants + AGO tags + test group)
                   ├─► post-silva-incident-http  ┐ same time
                   └─► trigger-pagerduty         ┘
Problem CLOSED → prepare-close-ids → resolve SILVA ∥ resolve PagerDuty
```
